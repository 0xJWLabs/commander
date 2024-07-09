local String = require('./utils/string')
local Types = require('./types')

type Argument = Types.Argument

local function humanReadableArgName(arg: Argument): string
    local nameOutput = arg:name() .. (arg.variadic == true and '...' or '')
    return arg.required and '<' .. nameOutput .. '>' or '[' .. nameOutput .. ']'
end

--[=[
    @class Argument
]=]
--[=[
    @prop description string
    @within Argument
]=]
--[=[
    @prop variadic boolean
    @within Argument
]=]
--[=[
    @prop parseArg ((value: string, previous: any) -> any)?
    @within Argument
]=]
--[=[
    @prop defaultValue any?
    @within Argument
]=]
--[=[
    @prop defaultValueDescription string?
    @within Argument
]=]
--[=[
    @prop required boolean
    @within Argument
]=]
--[=[
    @prop _name string
    @within Argument
]=]
local Argument = {}

Argument.prototype = {}
Argument.interface = {}

Argument.prototype.__type = 'Argument'

function Argument.interface.new(name: string, description: string?): Argument
    local argument = {
        variadic = false,
        description = description or '',
        defaultValue = nil,
        defaultValueDescription = nil,
        parseArg = nil,
    }

    local arg = (setmetatable(argument, {
        __index = Argument.prototype,
    }) :: any) :: Argument

    local firstChar = string.sub(name, 1, 1)

    if firstChar == '<' then
        arg.required = true
        arg._name = String.slice(name, 2, -1)
    elseif firstChar == '[' then
        arg.required = false
        arg._name = String.slice(name, 2, -1)
    end

    if #arg._name > 3 and String.slice(arg._name, -3) == '...' then
        arg.variadic = true
        arg._name = String.slice(arg._name, 1, -3)
    end

    return arg
end

--[=[
    Return argument name.

    @method name
    @within Argument

    @return string
]=]
function Argument.prototype.name(self: Argument): string
    return self._name
end

--[=[
    Set the default value, and optionally supply the description to be displayed in the help.

    @method default
    @within Argument

    @param value any
    @param description string?

    @return string
]=]
function Argument.prototype.default(self: Argument, value: any, description: string?): Argument
    self.defaultValue = value
    self.defaultValueDescription = description
    return self
end

--[=[
    Set the default value, and optionally supply the description to be displayed in the help.

    @method argParser 
    @within Argument

    @param fn (value: string, previous: any) -> any

    @return Option 
]=]
function Argument.prototype.argParser(self: Argument, fn: (value: string, previous: any) -> any): Argument
    self.parseArg = fn
    return self
end

return {
    Argument = Argument.interface,
    humanReadableArgName = humanReadableArgName,
}
