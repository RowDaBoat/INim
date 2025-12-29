# ISC License
# Copyright (c) 2025 RowDaBoat

import strutils
import tables
import input
import evaluation
import parser
import ../reploidvm/vm
import ../commands/commands


type Evaluator* = object
  commandsApi: CommandsApi
  commands: Table[string, Command]
  vm: ReploidVM


proc isEmpty(lines: string): bool =
  lines.strip().len == 0


proc getCommand(self: Evaluator, lines: string): (bool, Command, seq[string]) =
  let split = lines.splitWhitespace()
  let command = split[0]
  let args = split[1..^1]

  return if command in self.commands:
    (true, self.commands[command], args)
  else:
    (false, Command(), @[])


proc isImport(lines: string): Parser =
  lines.parse()
    .matchKeywords("import")
    .consumeSpaces()


proc isVariableDeclaration(lines: string): Parser =
  lines.parse()
    .matchKeywords("var", "let", "const")
    .consumeSpaces()
    .matchLabel()


proc isDeclaration(lines: string): Parser =
  lines.parse()
    .matchKeywords("type", "proc", "template", "macro", "func", "method", "iterator", "converter")
    .consumeSpaces()


proc toDeclarerKind(text: string): DeclarerKind =
  case text:
  of "const": return DeclarerKind.Const
  of "let": return DeclarerKind.Let
  of "var": return DeclarerKind.Var


proc processCommand(self: var Evaluator, lines: string, evaluation: var Evaluation): bool =
  let (isCommand, command, args) = self.getCommand(lines)

  if not isCommand:
    return false

  evaluation = command.run(self.commandsApi, args)
  return true


proc processImport(self: var Evaluator, lines: string, evaluation: var Evaluation): bool =
  let importResult = lines.isImport()
  if not importResult.ok:
    return false

  self.vm.declareImport(importResult.text)
  let updateImportsResult = self.vm.updateImports()

  evaluation = Evaluation(
    kind: if updateImportsResult.isSuccess: Success else: Error,
    result: updateImportsResult[0]
  )
  return true


proc getType(parser: var Parser): string =
  let typeParser = parser
    .consumeSpaces()
    .matchSymbols(":")
    .consumeSpaces()
    .matchLabel()

  if typeParser.ok:
    parser = typeParser
    return parser.tokens[^1]

  return ""


proc getInitializer(parser: var Parser): string =
  let initialiserParser = parser
    .consumeSpaces()
    .matchSymbols("=")

  if initialiserParser.ok:
    parser = initialiserParser
    return initialiserParser.text

  return ""


proc processVariableDeclaration(self: var Evaluator, lines: string, evaluation: var Evaluation): bool =
  var varDeclResult = lines.isVariableDeclaration()
  if not varDeclResult.ok:
    return false

  let declarer = varDeclResult.tokens[0].toDeclarerKind()
  let label = varDeclResult.tokens[1]
  let typ = varDeclResult.getType()
  let initializer = varDeclResult.getInitializer()

  self.vm.declareVar(declarer, label, typ, initializer)

  let updateStateResult = self.vm.updateState()

  evaluation = Evaluation(
    kind: if updateStateResult.isSuccess: Success else: Error,
    result: updateStateResult[0]
  )
  return true


proc processOtherDeclaration(self: var Evaluator, lines: string, evaluation: var Evaluation): bool =
  let declResult = lines.isDeclaration()
  if not declResult.ok:
    return false

  self.vm.declare(lines)
  let updateDeclarationsResult = self.vm.updateDeclarations()

  evaluation = Evaluation(
    kind: if updateDeclarationsResult.isSuccess: Success else: Error,
    result: updateDeclarationsResult[0]
  )
  return true


proc processRunCommand(self: var Evaluator, lines: string): Evaluation =
  let runResult = self.vm.runCommand(lines)
  return Evaluation(
    kind: if runResult.isSuccess: Success else: Error,
    result: runResult[0]
  )


proc evaluateLines(self: var Evaluator, lines: string): Evaluation =
  if lines.isEmpty():
    return Evaluation(kind: Empty)

  var evaluation = Evaluation(kind: Empty)

  if self.processCommand(lines, evaluation):
    return evaluation
  elif self.processImport(lines, evaluation):
    return evaluation
  elif self.processVariableDeclaration(lines, evaluation):
    return evaluation
  elif self.processOtherDeclaration(lines, evaluation):
    return evaluation
  else:
    return self.processRunCommand(lines)


proc newEvaluator*(
  commandsApi: CommandsApi,
  commands: Table[string, Command],
  vm: ReploidVM
): Evaluator = Evaluator(commandsApi: commandsApi, vm: vm, commands: commands)


proc eval*(self: var Evaluator, input: Input): Evaluation =
  case input.kind:
  of Lines: self.evaluateLines(input.lines)
  of Reset: Evaluation(kind: Empty)
  of Editor: Evaluation(kind: Empty)
  of Quit: Evaluation(kind: Quit)
  of EOF: Evaluation(kind: Quit)
