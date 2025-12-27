# ISC License
# Copyright (c) 2025 RowDaBoat

import commands
import ../repl/evaluation
import ../reploidvm/vm


proc sourceCmd*(commandsApi: var CommandsApi, args: seq[string]): Evaluation =
  case args[0]:
  of "imports":
    return Evaluation(kind: Success, result: commandsApi.vm.importsSource)
  of "declarations":
    return Evaluation(kind: Success, result: commandsApi.vm.declarationsSource)
  of "command":
    return Evaluation(kind: Success, result: commandsApi.vm.commandSource)
  else:
    return Evaluation(kind: Error, result: "Invalid source: " & args[0])
