local String = require('./utils/string')
local Table = require('./utils/table')
local Types = require('./types')

type Option = Types.Option

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

--[=[
    @class Option
]=]
--[=[
    @prop flags string
    @within Option
]=]
--[=[
    @prop description string
    @within Option
]=]
--[=[
    @prop required boolean
    @within Option
]=]
--[=[
    @prop optional boolean
    @within Option
]=]
--[=[
    @prop mandatory boolean
    @within Option
]=]
--[=[
    @prop hidden boolean
    @within Option
]=]
--[=[
    @prop short string?
    @within Option
]=]
--[=[
    @prop long string?
    @within Option
]=]
--[=[
    @prop defaultValue any?
    @within Option
]=]
--[=[
    @prop defaultValueDescription string?
    @within Option
]=]
--[=[
    @prop parseArg ((value: string, previous: any) -> any)?
    @within Option
]=]
local Option = {}

Option.prototype = {}
Option.interface = {}

Option.prototype.__type = 'Option'

function Option.interface.new(flags: string, description: string?): Option
    local optionFlags = splitOptionFlags(flags)
    local option = {
        flags = flags,
        description = description or '',
        required = String.includes(flags, '<'),
        optional = String.includes(flags, '%['),
        mandatory = false,
        short = optionFlags.shortFlag and '-' .. optionFlags.shortFlag or nil,
        long = optionFlags.longFlag and '--' .. optionFlags.longFlag or nil,
        defaultValue = nil,
        defaultValueDescription = nil,
        parseArg = nil,
        hidden = false,
    }

    local self = (setmetatable(option, {
        __index = Option.prototype,
    }) :: any) :: Option
    
    return self
end

--[=[
    Set tge default value, and optionally supply the description to be displayed in the help.

    @method default
    @within Option

    @param value any
    @param description string?
    
    @return Option
]=]
function Option.prototype.default(self: Option, value: any, description: string?): Option
    self.defaultValue = value
    self.defaultValueDescription = description

    return self
end

--[=[
    Set the custom handler for processing CLI option arguments into option values.

    @method argParser 
    @within Option

    @param fn (value: string, previous: any) -> any
    
    @return Option
]=]
function Option.prototype.argParser(self: Option, fn: (value: string, value: any) -> any): Option
   self.parseArg = fn

   return self
end

--[=[
    Whether the option is mandatory and must have a value after parsing.

    @method makeOptionMandatory 
    @within Option

    @param mandatory boolean? 
    
    @return Option
]=]
function Option.prototype.makeOptionMandatory(self: Option, mandatory: boolean?): Option
    local actualMandatory: boolean = mandatory == nil and true or mandatory :: boolean

    self.mandatory = not not actualMandatory 

    return self
end

--[=[
    Hide option in help,

    @method hideHelp 
    @within Option

    @param hide boolean? 
    
    @return Option
]=]
function Option.prototype.hideHelp(self: Option, hide: boolean?): Option
    local actualHide: boolean = hide == nil and true or hide :: boolean
    self.hidden = actualHide

    return self
end

--[=[
    Return option name. 

    @method name 
    @within Option

    @return string 
]=]
function Option.prototype.name(self: Option): string
    if self.long then
        local name = string.gsub(self.long, '^-%-', '')
        return name
    end

    local name = string.gsub(self.short :: string, '^-', '')
    return name
end

--[=[
    Return option name, in a camelcase format that can be used
    as a object attribute key

    @method attributeName
    @within Option

    @return string 
]=]
function Option.prototype.attributeName(self: Option): string
    return camelcase(self:name())
end

--[=[
    Check if `arg` matches the short or long flag. 

    @method is 
    @within Option

    @param arg string

    @return boolean
]=]
function Option.prototype.is(self: Option, arg: string): boolean
    return self.short == arg or self.long == arg
end

--[=[
    Return whether a boolean option.

    Options are one of boolean, negated, required argument, or optional argument.

    @method isBoolean
    @within Option

    @return boolean 
]=]
function Option.prototype.isBoolean(self: Option): boolean
    return not self.required and not self.optional
end

return Option.interface
