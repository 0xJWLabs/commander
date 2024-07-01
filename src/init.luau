local Commander = require("commander")
local CommandPrototype = require("commandPrototype")
local Option = require("option")
local Argument = require("argument")

export type Commander = Commander.Commander
export type Command = CommandPrototype.CommandPrototype<Commander>
export type Option = Option.Option<Commander>
export type Argument = Argument.Argument<Commander>

return {
    Commander = Commander,
    Command = CommandPrototype,
    Option = Option,
    Argument = Argument,
    program = Commander.new(),
    debugProgram = Commander.new(nil, nil, { debug = true })
}