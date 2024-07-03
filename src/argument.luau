local fstring = require("utils/fstring")

local Argument = {}

Argument.prototype = {}
Argument.interface = {}

Argument.prototype.__type = 'Argument'

local function humanReadableArgName(arg: Argument): string
    local nameOutput = arg:name() .. (arg.variadic == true and '...' or '')
    return arg.required and '<' .. nameOutput .. '>' or '[' .. nameOutput  .. ']'
end

function Argument.prototype.name(self: Argument): string
    return self._name
end

function Argument.interface.new(params: ArgumentParams): Argument
    local name = params.name

    local argument = {
        variadic = false,
        description = params.description or '',
        type = params.type,
        default = params.default,
    }

    local arg = (setmetatable(argument, {
        __index = Argument.prototype
    }) :: any) :: Argument

    local firstChar = string.sub(name, 1, 1)

    if firstChar == '<' then
        arg.required = true
        arg._name = fstring.slice(name, 2, -1)
    elseif firstChar == '[' then
        arg.required = false
        arg._name = fstring.slice(name, 2, -1)
    end

    if #arg._name > 3 and fstring.slice(arg._name, -3) == '...' then
        arg.variadic = true
        arg._name = fstring.slice(arg._name, 1, -3)
    end

    return arg
end

export type ArgumentParams = {
    name: string,
    type: string,
    default: any?,
    description: string?
}

export type Argument = {
    _name: string,
    type: string,
    default: string,
    description: string,
    variadic: boolean,
    required: boolean,
} & typeof(Argument.prototype)

return {
    Argument = Argument.interface,
    humanReadableArgName = humanReadableArgName
} 