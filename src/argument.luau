local Closers = {
    req = {left = "<", right = ">"},
    opt = {left = "[", right = "]"},
    optlist = {left = "[...", right = "]"}
}

local fstring = require("utils/fstring")

local Argument = {}

Argument.prototype = {}
Argument.interface = {}

Argument.prototype.__type = 'Argument'

function Argument.prototype.renderExtended<T>(self: Argument<T>): string
    local commander = self.commander :: any
    return `{commander._theme.command.argument.color(self:render())}{commander._theme.command.description.color(self.description and " " .. self.description or "")}{commander._theme.command.description.color(self.default and " (Default: " .. self.default .. ")" or "")}`
end

function Argument.prototype.render<T>(self: Argument<T>): string
    local closer = Closers[self.type] or {left = "", right = ""}
    return closer.left .. self:name() .. closer.right
end

function Argument.prototype.name<T>(self: Argument<T>): string
    return self._name
end

function Argument.interface.new<T>(params: ArgumentParams, commander: T): Argument<T>
    local name = params.name

    local argument = {
        variadic = false,
        description = params.description or '',
        type = params.type,
        default = params.default,
        commander = commander,
    }

    local arg = (setmetatable(argument, {
        __index = Argument.prototype
    }) :: any) :: Argument<T>

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

export type Argument<T> = {
    _name: string,
    type: string,
    default: string,
    description: string,
    commander: T,
    variadic: boolean,
    required: boolean,
} & typeof(Argument.prototype)

return Argument.interface