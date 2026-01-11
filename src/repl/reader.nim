# ISC License
# Copyright (c) 2025 RowDaBoat

import strutils, sequtils
import noise
import input, styledoutput


type Reader* = object
  noise: Noise
  output: Output
  promptMessage: string
  promptSymbol: string
  indentation: string
  historyFile: string

const MatchAnyIndentTriggers = [
  "object of "
]

const MatchLineEndIndentTriggers = [
  ",", "=", ":",
  "var", "let", "const", "type", "import",
  "object", "RootObj", "enum"
]

const BranchingTriggers = [
  "if ","when", "elif ", "try ", "try:", "except ", "except:"
]

proc setMainPrompt(self: var Reader) =
  let prompt = self.output.styledPrompt(self.promptMessage, self.promptSymbol & " ")
  self.noise.setPrompt(prompt)


proc setMultilinePrompt(self: var Reader) =
  let promptMessage = ".".repeat(self.promptMessage.len + self.promptSymbol.len - 1)
  let prompt = self.output.styledPrompt(promptMessage, ". ")
  self.noise.setPrompt(prompt)


proc setIndentation(self: var Reader, indentationLevels: int) =
  let indentation = self.indentation.repeat(max(indentationLevels, 0))
  self.noise.preloadBuffer(indentation, collapseWhitespaces = false)


proc handleBranching(branched: bool, indentation: int, line: string): bool =
  return if indentation == 0:
    BranchingTriggers.anyIt(line.startsWith(it))
  else:
    branched


proc indent(line: string): bool =
  if line.len == 0:
    return

  for trigger in MatchAnyIndentTriggers:
    if trigger in line:
      return true

  for trigger in MatchLineEndIndentTriggers:
    if line.strip().endsWith(trigger):
      return true


proc unindent(indentation: int, line: string, branched: bool): bool =
  let lineIsEmpty = line.strip.len == 0
  let unindentNonBranched = (not branched) and indentation > 0
  let unindentBranched = branched and indentation >= 0
  return lineIsEmpty and (unindentNonBranched or unindentBranched)


proc loadHistory(self: var Reader) =
  if self.historyFile != "":
    discard self.noise.historyLoad(self.historyFile)


proc saveHistory(self: var Reader) =
  if self.historyFile != "":
    discard self.noise.historySave(self.historyFile)


proc addHistory(self: var Reader, line: string) =
  self.noise.historyAdd(line)


proc readSingleLine(self: var Reader): Input =
  if not self.noise.readLine():
    case self.noise.getKeyType():
    of ktCtrlC:
      return Input(kind: Reset)
    of ktCtrlD:
      return Input(kind: Quit)
    else:
      return Input(kind: Lines, lines: "")

  var line =
    try: self.noise.getLine()
    except EOFError: return Input(kind: EOF)

  self.addHistory(line)
  return Input(kind: Lines, lines: line)


proc getIndentation(indentation: string, line: string): int =
  var line = line

  if indentation.len == 0:
    return 0

  while line.startsWith(indentation):
    inc result
    line = line[indentation.len..^1]


proc newReader*(
  output: Output,
  promptMessage: string = "reploid",
  promptSymbol: string = ">",
  indentation: string = "  ",
  historyFile: string = ""
): Reader =
  ## Creates a new Reader object with the given properties.
  ## `output` is used to output the prompt, which is composed by `promptMessage` and `promptSymbol`, defaults to "reploid>".
  ## `indentation` is used to auto-indent the lines, defaults to "  ".
  ## `historyFile` is used to load and save the history, by default no history is saved or loaded.
  var noise = Noise.init()

  result = Reader(
    noise: noise,
    output: output,
    promptMessage: promptMessage,
    promptSymbol: promptSymbol,
    indentation: indentation,
    historyFile: historyFile
  )
  result.loadHistory()


proc read*(self: var Reader): Input =
  ## Reads commands and signals.
  ##
  ## **Indentation:**
  ## The next line will be auto-indented when the current ends with one of:
  ## `,`, `=`, `:`, `var`, `let`, `const`, `type`, `import`, `object`, `RootObj`, `enum` and `object of X`
  ## The next line will be un-indented when a line is left empty.
  ## If the user manually indents or un-indents, the indentation will be adjusted accordingly.
  ## 
  ## **Branching:**
  ## Branching is opened when a non-indented line starts with one of the branching triggers: `if`, `when`, `elif`, `try` and `except`.
  ## When a non-indented line does not start with a branching trigger, branching is closed.
  ## This behavior gives space to introduce non-indented `elif`, `else`, `except` and `finally` branches.
  ## 
  ## **Completion:**
  ## The user's input is considered complete when either:
  ##   - branching is closed and a non-indented line is finished without triggering an auto-indent.
  ##   - branching is opened and an empty non-indented line is introduced.
  ##
  ## **EOF and Signals:**
  ## - `Ctrl+D` is captured and returned as a `Quit` input.
  ## - `Ctrl+C` is captured and returned as a `Reset` input.
  ## - An `EOF` from `stdin` is returned as an `EOF` input.
  ##
  ## **History:**
  ## Each line is added to the history file.
  var completed = false
  var branched = false
  var indentation = 0
  var lines: seq[string] = @[]

  self.setMainPrompt()

  while not completed:
    var singleLineResult = readSingleLine(self)

    if singleLineResult.kind != Lines:
      return singleLineResult

    let line = singleLineResult.lines

    indentation = getIndentation(self.indentation, line)
    branched = handleBranching(branched, indentation, line)

    if indent(line):
      indentation += 1

    if unindent(indentation, line, branched):
      indentation -= 1

    if line.strip.len > 0:
      lines.add(line)

    self.setMultilinePrompt()
    self.setIndentation(indentation)

    let branchCompleted = branched and indentation == -1
    let regularCompleted = not branched and indentation == 0
    completed = branchCompleted or regularCompleted

  result = Input(kind: Lines, lines: lines.join("\n"))


proc close*(self: var Reader) =
  ## closes the reader, saving its history.
  self.saveHistory()
