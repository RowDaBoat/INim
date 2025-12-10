import dynlib
import accessors

const state0Path = "./libstate0.dylib"
const state1Path = "./libstate1.dylib"
const state2Path = "./libstate2.dylib"
const commandPath = "./libcommand.dylib"

proc main =
  let state0 = loadLib(state0Path)
  let state1 = loadLib(state1Path)
  let state2 = loadLib(state2Path)
  let command = loadLib(commandPath)

  if state0.isNil or state1.isNil or state2.isNil or command.isNil:
    quit("Failed to load a library.")

  let get0ValueProc = cast[GetValue](state0.symAddr("getValue"))
  let set0ValueProc = cast[SetValue](state0.symAddr("setValue"))

  let get1ValueProc = cast[GetValue](state1.symAddr("getValue"))
  let set1ValueProc = cast[SetValue](state1.symAddr("setValue"))

  let get2ValueProc = cast[GetValue](state1.symAddr("getValue"))
  let set2ValueProc = cast[SetValue](state1.symAddr("setValue"))

  let commandProc = cast[Command](command.symAddr("runCommand"))

  let state0Accessors = StateAccessors(
    getValue: get0ValueProc,
    setValue: set0ValueProc
  )
  let state1Accessors = StateAccessors(
    getValue: get1ValueProc,
    setValue: set1ValueProc
  )
  let state2Accessors = StateAccessors(
    getValue: get2ValueProc,
    setValue: set2ValueProc
  )

  commandProc(state0Accessors, state1Accessors)
  commandProc(state1Accessors, state2Accessors)
  commandProc(state2Accessors, state0Accessors)

main()
