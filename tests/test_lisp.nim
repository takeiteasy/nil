import unittest
import lisp

suite "lisp macro tests":
  test "simple addition":
    let result = lisp("(+ 1 2)")
    check(result == 3)

  test "if expression":
    let result = lisp("(if (> 5 3) 10 20)")
    check(result == 10)

  test "let expression":
    let result = lisp("(let ((a 10) (b 20)) (+ a b))")
    check(result == 30)

  test "lambda expression":
    let square = lisp("(lambda ((x int)) (* x x))")
    check(square(5) == 25)

  test "list operations":
    let mylist = lisp("(cons 1 (cons 2 (cons 3 @[])))")
    check(mylist == @[1, 2, 3])
    let car_res = lisp("(car mylist)")
    check(car_res == 1)
    let cdr_res = lisp("(cdr mylist)")
    check(cdr_res == @[2, 3])
