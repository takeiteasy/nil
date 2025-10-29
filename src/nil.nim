import macros, strutils

# Helper to check if a node is a symbol with a specific name
proc isSymbol(n: NimNode, name: string): bool =
  n.kind == nnkIdent and n.strVal == name

# Main macro that transforms Lisp-like syntax to Nim
macro lisp*(body: untyped): untyped =
  proc transform(n: NimNode): NimNode =
    case n.kind
    of nnkCall, nnkCommand:
      # Handle special forms first
      if n.len > 0:
        let op = n[0]
        
        # (if condition then else)
        if op.isSymbol("if"):
          if n.len != 4:
            error("if requires 3 arguments: condition, then, else", n)
          result = nnkIfExpr.newTree(
            nnkElifBranch.newTree(
              transform(n[1]),
              transform(n[2])
            ),
            nnkElse.newTree(transform(n[3]))
          )
        
        # (let ((var val) ...) body)
        elif op.isSymbol("let"):
          if n.len != 3:
            error("let requires 2 arguments: bindings and body", n)
          let bindings = n[1]
          if bindings.kind != nnkPar:
            error("let bindings must be in parentheses", bindings)
          
          result = nnkStmtList.newTree()
          for binding in bindings:
            if binding.kind != nnkPar or binding.len != 2:
              error("each binding must be (name value)", binding)
            let varName = binding[0]
            let varVal = transform(binding[1])
            result.add nnkLetSection.newTree(
              nnkIdentDefs.newTree(
                varName,
                newEmptyNode(),
                varVal
              )
            )
          result.add transform(n[2])
          result = nnkBlockStmt.newTree(newEmptyNode(), result)
        
        # (lambda (args...) body)
        elif op.isSymbol("lambda"):
          if n.len != 3:
            error("lambda requires 2 arguments: params and body", n)
          let params = n[1]
          if params.kind != nnkPar:
            error("lambda params must be in parentheses", params)
          
          var formalParams = nnkFormalParams.newTree(newEmptyNode())
          for param in params:
            formalParams.add nnkIdentDefs.newTree(
              param,
              newEmptyNode(),
              newEmptyNode()
            )
          
          result = nnkLambda.newTree(
            newEmptyNode(),
            newEmptyNode(),
            newEmptyNode(),
            formalParams,
            newEmptyNode(),
            newEmptyNode(),
            transform(n[2])
          )
        
        # (do expr1 expr2 ...)
        elif op.isSymbol("do"):
          result = nnkStmtList.newTree()
          for i in 1..<n.len:
            result.add transform(n[i])
        
        # Regular function call
        else:
          result = nnkCall.newTree()
          for i in 0..<n.len:
            result.add transform(n[i])
      else:
        result = n
    
    of nnkPar:
      # Empty parentheses or grouped expression
      if n.len == 0:
        result = newNilLit()
      elif n.len == 1:
        result = transform(n[0])
      else:
        # Treat as a call
        result = nnkCall.newTree()
        for child in n:
          result.add transform(child)
    
    of nnkPrefix, nnkInfix:
      # Transform operators
      result = copyNimNode(n)
      for child in n:
        result.add transform(child)
    
    else:
      # Literals, identifiers, etc - pass through
      result = n
    
    return result
  
  result = transform(body)

# Example usage
when isMainModule:
  # Simple arithmetic
  let x = lisp:
    (+ 1 2)
  echo "1 + 2 = ", x
  
  # If expression
  let y = lisp:
    (if (> 5 3)
      "five is greater"
      "three is greater")
  echo y
  
  # Let bindings
  let z = lisp:
    (let ((a 10) (b 20))
      (+ a b))
  echo "a + b = ", z
  
  # Lambda
  let square = lisp:
    (lambda (x) (* x x))
  echo "square(7) = ", square(7)
  
  # Do block (sequence of expressions)
  lisp:
    (do
      (echo "First")
      (echo "Second")
      (echo "Third"))
  
  # More complex example
  let factorial = lisp:
    (lambda (n)
      (if (<= n 1)
        1
        (* n (factorial (- n 1)))))
  
  echo "factorial(5) = ", factorial(5)