# Package

skipDirs      = @["tests"]
version       = "1.0.0"
author        = "Andrei Regiani"
description   = "Interactive Nim Shell / REPL / Playground"
license       = "MIT"
installDirs   = @["src"]
installExt    = @["nim"]
bin           = @["inim"]

srcDir        = "src"

requires "cligen >= 1.5.22" #TODO: remove
requires "https://github.com/RowDaBoat/cliquet.git#master"
requires "https://github.com/jangko/nim-noise.git#master"
requires "https://github.com/beef331/nimscripter.git"

task test, "Run all tests":
  exec "mkdir -p bin"
  exec "nim c -d:NoColor -d:prompt_no_history --out:bin/inim src/inim.nim"
  exec "nim c -r -d:prompt_no_history tests/test.nim"
  exec "nim c -r -d:prompt_no_history tests/test_nims_backend.nim"
  # Recompile with tty checks
  exec "nim c -d:NoColor -d:NOTTYCHECK -d:prompt_no_history --out:bin/inim src/inim.nim"
  exec "nim c -r -d:withTools -d:prompt_no_history tests/test_commands.nim"
  exec "nim c -r -d:prompt_no_history tests/test_interface.nim"
