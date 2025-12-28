# ISC License
# Copyright (c) 2025 RowDaBoat

import unittest
import ../src/reploidvm/vm
import ../src/reploidvm/compiler
import strutils

suite "Reploid VM should:":
  setup:
    let nim = newNimCompiler("nim", @[])
    var vm = newReploidVM(nim)
    var result: (string, int)

  teardown:
    vm.clean()


  test "run a simple command":
    result = vm.runCommand("echo \"Protobot.\"")
    check result == ("", 0)


  test "return an int value":
    let value = 100001
    result = vm.runCommand($value)
    check result == ("'" & $value & "' type: int", 0)


  test "return a string value":
    let value = "Protobot."
    result = vm.runCommand('"' & value & '"')
    check result == ("'" & value & "' type: string", 0)


  test "declare a variable":
    vm.declareVar("var", "x", "int", " = 20")

    result = vm.updateState()
    check result == ("", 0)

    result = vm.runCommand("x")
    check result == ("'20' type: int", 0)


  test "update the value of a variable":
    vm.declareVar("var", "x", "int", " = 20")

    result = vm.updateState()
    check result == ("", 0)

    result = vm.runCommand("inc x")
    check result == ("", 0)

    result = vm.runCommand("x")
    check result == ("'21' type: int", 0)


  test "update many times the value of a variable":
    let start = 20
    vm.declareVar("var", "x", "int", " = " & $start)

    result = vm.updateState()
    check result == ("", 0)

    for i in 0 ..< 5:
      result = vm.runCommand("inc x")
      check result == ("", 0)

      result = vm.runCommand("x")
      check result == ("'" & $(start + i + 1) & "' type: int", 0)


  test "initialize a string variable":
    let value = "Protobot."
    vm.declareVar("var", "x", "string", " = \"" & value & "\"")

    result = vm.updateState()
    check result == ("", 0)

    result = vm.runCommand("x")
    check result == ("'" & value & "' type: string", 0)


  test "import a library":
    # TODO: the argument should not have to include the "import" keyword
    vm.declareImport("import strutils")

    result = vm.updateImports()
    check result[1] == 0

    result = vm.runCommand("@[\"Imports\", \"are\", \"working.\"].join(\" \")")
    check result == ("'Imports are working.' type: string", 0)


  test "import a local source file":
    vm.declareImport("import test/localcode")
    result = vm.updateImports()
    check result[1] == 0

    result = vm.runCommand("newTest(\"Test\", 10)")
    check result == ("'[name: Test count: 10]' type: Test", 0)


  test "not crash when using a ref object":
    vm.declare("""
      type R = ref object
    """.unindent(6))

    vm.declare("""
      type O = object
        r: R
        s: seq[int]
    """.unindent(6))

    discard vm.updateDeclarations()
    vm.declareVar("var", "o", "O", "")

    discard vm.updateState()
    vm.declareVar("var", "u", "O", "")

    discard vm.updateState()
    check result == ("", 0)
