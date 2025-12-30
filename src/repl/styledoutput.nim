# ISC License
# Copyright (c) 2025 RowDaBoat

import terminal
import options
import noise/styler


type
  ColorScheme* = object
    fg*: Option[(ForegroundColor, bool)]
    bg*: Option[(BackgroundColor, bool)]


type Output* = object
  nim*: ColorScheme
  promptMessage*: ColorScheme
  promptSymbol*: ColorScheme
  okResult*: ColorScheme
  info*: ColorScheme
  warning*: ColorScheme
  error*: ColorScheme


proc colorScheme*(
  fgColor: ForegroundColor = fgDefault,
  fgBright: bool = false,
  bgColor: BackgroundColor = bgDefault,
  bgBright: bool = false
): ColorScheme =
  ColorScheme(
    fg: if fgColor != fgDefault: some((fgColor, fgBright)) else: none[(ForegroundColor, bool)](),
    bg: if bgColor != bgDefault: some((bgColor, bgBright)) else: none[(BackgroundColor, bool)]()
  )


proc newOutput*(
  colors: bool = true,
  nim: ColorScheme = colorScheme(fgYellow, true),
  promptMessage: ColorScheme = colorScheme(fgYellow, false),
  promptSymbol: ColorScheme = colorScheme(),
  okResult: ColorScheme = colorScheme(fgCyan, false),
  info: ColorScheme = colorScheme(),
  warning: ColorScheme = colorScheme(fgYellow, false),
  error: ColorScheme = colorScheme(fgRed, false),
): Output =
  ## Creates a new Output object with the given color schemes.
  ## The object output schemes are
  ## - prompt message and symbol: the console's prompt colors.
  ## - ok result: colors for a succesful result.
  ## - info: colors for information messages.
  ## - warning: colors for warning messages.
  ## - error: colors for error messages.
  ## - nim: colors used just to stylize nim mentions.
  if not colors:
    let noColor = colorScheme()
    return Output(
      nim: noColor, promptMessage: noColor, promptSymbol: noColor,
      okResult: noColor, info: noColor, warning: noColor, error: noColor
    )
  else:
    return Output(
      nim: nim, promptMessage: promptMessage, promptSymbol: promptSymbol,
      okResult: okResult, info: info, warning: warning, error: error
    )


proc write*(self: Output, message: string, color: ColorScheme = colorScheme()) =
  ## Writes a message with the given color scheme.
  let fg = color.fg
  let bg = color.bg

  if fg.isSome:
    stdout.setForegroundColor(fg.get[0], fg.get[1])

  if bg.isSome:
    stdout.setBackgroundColor(bg.get[0], bg.get[1])

  stdout.write(message)
  stdout.resetAttributes()
  stdout.flushFile()


proc nim*(self: Output, message: string) =
  ## Writes a message with the nim color scheme.
  self.write(message, self.nim)


proc promptMessage*(self: Output, message: string) =
  ## Writes a message with the prompt message color scheme.
  self.write(message, self.promptMessage)


proc promptSymbol*(self: Output, message: string) =
  ## Writes a message with the prompt symbol color scheme.
  self.write(message, self.promptSymbol)


proc okResult*(self: Output, message: string) =
  ## Writes a message with the ok result color scheme.
  self.write(message, self.okResult)


proc info*(self: Output, message: string) =
  ## Writes a message with the info color scheme.
  self.write(message, self.info)


proc warning*(self: Output, message: string) =
  ## Writes a message with the warning color scheme.
  self.write(message, self.warning)


proc error*(self: Output, message: string) =
  ## Writes a message with the error color scheme.
  self.write(message, self.error)


proc unstyled*(self: Output, message: string) =
  ## Writes a message without any color scheme.
  self.write(message, colorScheme())


proc styledPrompt*(self: Output, message: string, symbol: string): Styler =
  ## Creates a styled prompt with the given message and symbol.
  var styler = Styler.init()
  var messageFg = self.promptMessage.fg
  var messageBg = self.promptMessage.bg
  var symbolFg = self.promptSymbol.fg
  var symbolBg = self.promptSymbol.bg

  if messageFg.isSome:
    styler.addCmd(messageFg.get[0])

  if messageBg.isSome:
    styler.addCmd(messageBg.get[0])

  styler.addCmd(message)
  styler.addCmd(TerminalCmd.resetStyle)

  if symbolFg.isSome:
    styler.addCmd(symbolFg.get[0])

  if symbolBg.isSome:
    styler.addCmd(symbolBg.get[0])

  styler.addCmd(symbol)
  styler.addCmd(TerminalCmd.resetStyle)

  return styler
