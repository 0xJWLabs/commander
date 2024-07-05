local String = require('./utils/string')
local Table = require('./utils/table')

local function splitOptionFlags(flags: string)
    local shortFlag
    local longFlag

    -- Use original very loose parsing to maintain backwards compatibility
    -- Split flags based on spaces or commas followed by any number of spaces
    local flagParts = {}

    for part in flags:gmatch('[^%s|,]+') do
        table.insert(flagParts, part)
    end

    if #flagParts > 1 and not flagParts[2]:match('^%[<[') then
        shortFlag = table.remove(flagParts, 1)
    end

    longFlag = table.remove(flagParts, 1)

    local optType = flagParts[1] and 'normal' or 'flag'

    -- local optType = flagParts[1] and string.gsub(flagParts[1], "[<>%[%]]", "") or 'flag'

    -- Add support for lone short flag without significantly changing parsing
    if not shortFlag and longFlag and longFlag:match('^%-[^%-]$') then
        shortFlag = longFlag
        longFlag = nil
    end

    if longFlag then
        longFlag = string.gsub(longFlag, '^-%-', '')
    end

    if shortFlag then
        shortFlag = string.gsub(shortFlag, '^-', '')
    end

    return { shortFlag = shortFlag, longFlag = longFlag, optType = optType }
end

local function camelcase(str: string)
    local splittedString = string.split(str, '-')

    return Table.reduce(splittedString, function(str: string, word)
        local wordSplit = string.split(word, '')
        return str .. wordSplit[1]:upper() .. String.slice(word, 2)
    end)
end

local Option = {}

Option.prototype = {}
Option.interface = {}

Option.prototype.__type = 'Option'

function Option.prototype.name(self: Option): string
    if self.long then
        local name = string.gsub(self.long, '^-%-', '')
        return name
    end

    local name = string.gsub(self.short :: string, '^-', '')
    return name
end

function Option.prototype.is(self: Option, arg: string)
    return self.short == arg or self.long == arg
end

function Option.prototype.attributeName(self: Option): string
    return camelcase(self:name())
end

function Option.prototype.hide(self: Option, hide: boolean?): Option
    local actualHide: boolean = hide == nil and true or hide :: boolean
    self.hidden = actualHide

    return self
end

function Option.interface.new(params: OptionParams): Option
    local flags = params.flags
    local optionFlags = splitOptionFlags(flags)
    local argument = {
        short = optionFlags.shortFlag and '-' .. optionFlags.shortFlag or nil,
        long = optionFlags.longFlag and '--' .. optionFlags.longFlag or nil,
        flags = flags,
        hidden = params.hidden,
        description = params.description or '',
        type = optionFlags.optType,
        default = params.default == 'nil' and nil or params.default,
        file = params.file,
        transform = if params.transform ~= nil and typeof(params.transform) == 'function'
            then params.transform
            else function(param)
                return param
            end,
    }

    if argument.type == 'flag' then
        argument.default = false
    end

    return (setmetatable(argument, {
        __index = Option.prototype,
    }) :: any) :: Option
end

export type OldOptionParams = {
    short: string?,
    long: string?,
    description: string?,
    type: string?,
    default: any?,
    file: any?,
    hidden: boolean?,
    transform: ((param: any) -> any)?,
}

export type OptionParams = {
    flags: string,
    description: string?,
    default: any?,
    file: any?,
    transform: ((param: any) -> any)?,
    hidden: boolean?,
}

export type Option = {
    hidden: boolean?,
    short: string?,
    long: string?,
    flags: string,
    description: string,
    type: string,
    default: any?,
    file: any,
    transform: (param: any) -> any,
} & typeof(Option.prototype)

return Option.interface
