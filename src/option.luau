-- local Closers = {
--     req = {left = "<", right = ">"},
--     opt = {left = "[", right = "]"},
--     optlist = {left = "[...", right = "]"}
-- }

local fstring = require("utils/fstring")

type reduceFn<T, U> = (previousValue: U, currentValue: T, currentIndex: number, array: { T }) -> U

local function reduce<T, U>(array: { T}, callback: reduceFn<T, U>, initialValue: U?): U
    if typeof(array) ~= "table" then
        error(string.format("reduce called on %s", typeof(array)))
    end
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

	local length = #array

	local value: T | U
	local initial = 1

	if initialValue ~= nil then
		value = initialValue
	else
		initial = 2
		if length == 0 then
			error("reduce of empty array with no initial value")
		end
		value = array[1]
	end

	for i = initial, length do
		value = callback(value :: U, array[i], i, array)
	end

	return value :: U
end

local function splitOptionFlags(flags: string)
    local shortFlag
    local longFlag

    -- Use original very loose parsing to maintain backwards compatibility
    -- Split flags based on spaces or commas followed by any number of spaces
    local flagParts = {}

    for part in flags:gmatch("[^%s|,]+") do
        table.insert(flagParts, part)
    end 


    if #flagParts > 1 and not flagParts[2]:match("^%[<[") then
        shortFlag = table.remove(flagParts, 1)
    end


    longFlag = table.remove(flagParts, 1)


    local optType = flagParts[1] and 'normal' or 'flag'

    -- local optType = flagParts[1] and string.gsub(flagParts[1], "[<>%[%]]", "") or 'flag'

    -- Add support for lone short flag without significantly changing parsing
    if not shortFlag and longFlag and longFlag:match("^%-[^%-]$") then
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

local function camelcase(str)
   local splittedString = string.split(str, '-')
   
   return reduce(splittedString, function(str: string, word)
        local wordSplit = string.split(word, '')
        return str .. wordSplit[1]:upper() .. fstring.slice(word, 2);
   end)
end

local Option = {}

Option.prototype = {}
Option.interface = {}

Option.prototype.__type = 'Option'

function Option.prototype.renderExtended<T>(self: Option<T>): string
    local commander = self.commander :: any
    return commander._theme.command.option.color(self.flags) .. " => " .. commander._theme.command.description.color(self.description .. (not (self.default == nil) and " (default: \"" .. tostring(self.default) .. "\")" or ""))
end

function Option.prototype.render<T>(self: Option<T>): string
    return self.flags 
end

function Option.prototype.name<T>(self: Option<T>): string
    if self.long then
        local name = string.gsub(self.long, '^-%-', '')
        return name
    end

    local name = string.gsub(self.short :: string, '^-', '')
    return name
end

function Option.prototype.attributeName<T>(self: Option<T>): string
    return camelcase(self:name())
end

function Option.interface.new<T>(params: OptionParams, commander: T): Option<T>
    local flags = params.flags
    local optionFlags = splitOptionFlags(flags)
    local argument = {
        short = optionFlags.shortFlag and "-" .. optionFlags.shortFlag or nil,
        long = optionFlags.longFlag and "--" .. optionFlags.longFlag or nil,
        flags = flags,
        hide = params.hide,
        description = params.description or '',
        type = optionFlags.optType,
        default = params.default,
        file = params.file,
        transform = if params.transform ~= nil and typeof(params.transform) == "function" then params.transform else function(param) return param end,
        commander = commander
    }

    if argument.type == 'flag' then
        argument.default = false
    end

    return (setmetatable(argument, {
        __index = Option.prototype
    }) :: any) :: Option<T>
end

export type OldOptionParams = {
    short: string?,
    long: string?,
    description: string?,
    type: string?,
    default: any?,
    file: any?,
    hide: boolean?,
    transform: ((param: any) -> any)?
}

export type OptionParams = {
    flags: string, 
    description: string?,
    default: any?,
    file: any?,
    transform: ((param: any) -> any)?,
    hide: boolean?,
}

export type Option<T> = {
    hide: boolean?,
    short: string?,
    long: string?,
    flags: string,
    description: string,
    type: string,
    default: any?,
    file: any,
    transform: ((param: any) -> any),
    commander: T
} & typeof(Option.prototype)

return Option.interface