local Argument = require('./argument')
local Command = require('./command')
local Option = require('./option')

export type Command = Command.Command 
export type Option = Option.Option
export type Argument = Argument.Argument

return {
    Command = Command,
    Option = Option,
    Argument = Argument,
    program = Command.new(),
}
