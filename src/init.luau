local Argument = require('./argument')
local Command = require('./command')
local Option = require('./option')
local Types = require('./types')

export type Command = Command.Command
export type Option = Types.Option
export type Argument = Types.Argument

return {
    Command = Command,
    Option = Option,
    Argument = Argument,
    program = Command.new(),
    debugProgram = Command.new(nil, true),
}
