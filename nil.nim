# Nim Implementation of Lisp

# Copyright (C) 2025 George Watson

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import os
import lisp
import osproc

proc doRepl() =
  echo "nil repl (type Ctrl-D to exit)"
  while true:
    try:
      stdout.write "> "
      stdout.flushFile()
      let line = stdin.readLine()
      if line.len > 0:
        # Show the generated Nim for the entered s-expression
        try:
          let nimSrc = lispToNim(line)
          echo nimSrc
        except Exception as e:
          echo "Error: ", e.msg
    except EOFError:
      break
    except Exception as e:
      echo "Error: ", e.msg

proc compileFile(inFilename: string) =
  if not fileExists(inFilename):
    echo "Error: file not found: ", inFilename
    quit(1)
  let content = readFile(inFilename)
  let nimCode = lispToNim(content)
  let outFilename = changeFileExt(inFilename, ".nim")
  writeFile(outFilename, nimCode)
  echo "Wrote ", outFilename

proc runFile(inFilename: string) =
  # Generate a .nim file and attempt to compile+run it using the Nim compiler.
  if not fileExists(inFilename):
    echo "Error: file not found: ", inFilename
    quit(1)
  let content = readFile(inFilename)
  let nimCode = lispToNim(content)
  let outFilename = changeFileExt(inFilename, ".nim")
  writeFile(outFilename, nimCode)
  echo "Wrote ", outFilename

  # Try to compile and run with `nim c --path:. -r <outFilename>`
  let cmd = "nim c --path:. -r " & outFilename
  try:
    let output = execCmd(cmd)
    echo output
  except OSError as e:
    echo "Failed to run compiler: ", e.msg
    echo "You can run this yourself: nim c --path:. -r ", outFilename

proc showHelp() =
  echo "nil (Nim Implementation of Lisp)"
  echo "https://github.com/takeiteasy/nil"
  echo ""
  echo "Usage:"
  echo "  nil run <file>      # compile and run a .lisp/.nil file"
  echo "  nil compile <file>  # emit a .nim file from input"
  echo "  nil repl            # interactive REPL (prints generated Nim)"
  echo "  nil -h|--help       # show this help"

proc main() =
  if paramCount() == 0:
    showHelp()
    return

  let cmd = paramStr(1)
  case cmd
  of "run":
    if paramCount() < 2:
      echo "run requires a filename"
      quit(1)
    runFile(paramStr(2))
  of "compile":
    if paramCount() < 2:
      echo "compile requires a filename"
      quit(1)
    compileFile(paramStr(2))
  of "repl":
    doRepl()
  of "-h", "--help":
    showHelp()
  else:
    echo "Unknown command: ", cmd
    showHelp()
    quit(1)

when isMainModule:
  main()