local ArgumentModule = require('argument')
local Option = require('option')
local Table = require('utils/table')
local fstring = require('utils/fstring')

local Argument = ArgumentModule.Argument

type Argument = ArgumentModule.Argument
type Option = Option.Option
type OptionParams = Option.OptionParams
type ArgumentParams = ArgumentModule.ArgumentParams

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
        longFlag = string.gsub(longFlag, '-', '')
    end

    if shortFlag then
        shortFlag = string.gsub(shortFlag, '-', '')
    end

    return { shortFlag = shortFlag, longFlag = longFlag, optType = optType }
end

local CommandPrototype = {}

CommandPrototype.prototype = {}
CommandPrototype.interface = {}

CommandPrototype.prototype.__type = 'CommandPrototype'

function CommandPrototype.prototype.action(self: CommandPrototype, fn: (...any) -> ())
    assert(fn, 'fn <function> is required for ' .. self.name .. ' command')
    self.fn = fn

    return self
end

function CommandPrototype.prototype.replaceArgument(
    self: CommandPrototype,
    argname: string,
    description: string?,
    default: string?
): CommandPrototype
    assert(argname, 'argument for ' .. self.name .. ' command')
    for _, v in self.arguments do
        if v._name == argname then
            v.description = (not (description == nil) and description) or v.description
            v.default = (not (default == nil) and default) or v.default
        end
    end

    return self
end

function CommandPrototype.prototype.hasOpt(self: CommandPrototype, opt: string): Option?
    return Table.Find(self.options, function(value)
        if value.long == opt or value.short == opt then
            return true
        end

        return false
    end)
end

function CommandPrototype.prototype.names(self: CommandPrototype)
    local names = { self.name }
    Table.ForEach(self.alias, function(alias)
        table.insert(names, alias)
    end)

    return names
end

function CommandPrototype.prototype.description(self: CommandPrototype, description: string): CommandPrototype
    self._description = description

    return self
end

function CommandPrototype.prototype.option(
    self: CommandPrototype,
    flags: string,
    description: string?,
    default: any?,
    hide: boolean?,
    transform: ((...any) -> ())?
): CommandPrototype
    assert(flags, 'opt <flags> is required for ' .. self.name .. ' command')
    local flagSplit = splitOptionFlags(flags)

    local config = {
        flags = flags,
        description = description,
        transform = transform,
        type = flagSplit.optType,
        default = default,
        hide = hide,
    }

    local option = self:optionCreator(config)
    table.insert(self.options, option)
    table.sort(self.options, function(a, b)
        return a:name() < b:name()
    end)

    return self
end

-- function CommandPrototype.prototype.option(
--     self: CommandPrototype,
--     long: string | Option.OptionParams,
--     short: string,
--     description: string?,
--     type: string?,
--     default: any?,
--     transform: ((...any) -> ())?
-- ): CommandPrototype
--     assert(long, 'opt <long> is required for ' .. self.name .. ' command')
--     local config: OptionParams
--     if typeof(long) == 'table' then
--         config = long
--     else
--         assert(short, 'opt <short> is required for ' .. self.name .. ' command')
--         config = {
--             long = long,
--             short = short,
--             description = description,
--             transform = transform,
--             type = type,
--             default = default,
--         }
--     end

--     local option = self:optionCreator(config)
--     table.insert(self.options, option)
--     table.sort(self.options, function(a, b)
--         return a.name < b.name
--     end)

--     return self
-- end

function CommandPrototype.prototype.run(self: CommandPrototype, ...: any)
    return self.fn(...)
end

function CommandPrototype.prototype.setAlias(self: CommandPrototype, alias: string | { string })
    assert(
        type(alias) == 'table' or type(alias) == 'string',
        'Alias should be a table (like-array) or a string'
    )
    if type(alias) == 'table' then
        self.alias = alias
    else
        self.alias = { alias }
    end
    return self
end

function CommandPrototype.prototype.argument(
    self: CommandPrototype,
    argument: string,
    description: string?,
    default: string?
)
    local word = string.match(argument, '[%w_-]+') :: string
    if argument == '<' .. word .. '>' then
        table.insert(
            self.arguments,
            self:argumentCreator({
                name = argument,
                type = 'req',
                description = description,
                default = default,
            })
        )
    elseif argument == '[' .. word .. ']' then -- Optional arguments
        table.insert(
            self.arguments,
            self:argumentCreator({
                name = argument,
                type = 'opt',
                description = description,
                default = default,
            })
        )
    elseif argument == '[' .. word .. '...]' or argument == '[...' .. word .. ']' then -- Optional List arguments
        table.insert(
            self.arguments,
            self:argumentCreator({
                name = argument,
                type = 'optlist',
                description = description,
                default = default,
            })
        )
    else
        error('Defining command argument. command: ' .. self.name .. ' word: ' .. word)
    end

    return self
end

function CommandPrototype.prototype.checkParsed(self: CommandPrototype, parsed)
    local required: { { name: string, type: string, typearg: string } } =
        {} :: { { name: string, type: string, typearg: string } }
    if #self.arguments > 0 then -- Parse required and optional arguments
        for _, cmd_arg in ipairs(self.arguments) do
            if parsed[cmd_arg:name()] == nil and cmd_arg.type == 'req' then
                table.insert(
                    required,
                    { name = cmd_arg:name(), type = cmd_arg.type :: string, typearg = 'argument' }
                )
            end
        end
    end
    local err = 'Default action has required arguments what are not defined: '
    Table.ForEach(required, function(value, _)
        err ..= value.name .. ', '
    end)
    if not (#required == 0) then
        error(err)
    end
    return (#required == 0)
end

function CommandPrototype.prototype.__parser(
    self: CommandPrototype,
    command: string,
    defaults: any
)
    local result = {}
    defaults = defaults or {}
    local inputs = fstring.split(command, '%S+')
    Table.ForEach(inputs, function(input, index)
        local word = string.match(input, '[%w_-]+') :: string
        local config = defaults[word]
        if not (typeof(config) == 'table') then
            config = { description = (type(config) == 'string' and config) or '', default = nil }
        end

        if word == input and index == 1 then
            self.name = word
        elseif input == '<' .. word .. '>' then
            table.insert(
                self.arguments,
                self:argumentCreator({
                    name = input,
                    type = 'req',
                    description = config.description,
                    default = config.default,
                })
            )
        elseif input == '[' .. word .. ']' then -- Optional arguments
            table.insert(
                self.arguments,
                self:argumentCreator({
                    name = input,
                    type = 'opt',
                    description = config.description,
                    default = config.default,
                })
            )
        elseif input == '[' .. word .. '...]' or input == '[...' .. word .. ']' then -- Optional List arguments
            table.insert(
                self.arguments,
                self:argumentCreator({
                    name = input,
                    type = 'optlist',
                    description = config.description,
                    default = config.default,
                })
            )
        else
            error('Defining command argument. command: ' .. command .. ' word: ' .. word)
        end
    end)

    return result
end

function CommandPrototype.prototype.argumentCreator(
    _: CommandPrototype,
    options: ArgumentParams
): Argument
    local argument = Argument.new(options)
    return argument
end

function CommandPrototype.prototype.optionCreator(
    _: CommandPrototype,
    options: OptionParams
): Option
    local option = Option.new(options)
    return option
end

function CommandPrototype.interface.new(
    command: string,
    config: Config?
): CommandPrototype
    local actualConfig: Config = config or {} :: Config
    actualConfig.arguments = (actualConfig.arguments or {}) :: any

    local self = {
        name = nil,
        _description = actualConfig.description or '',
        hide = (not (actualConfig.hide == nil) and actualConfig.hide) or false,
        alias = actualConfig.alias or {},
        positional_args = actualConfig.positional_args or {},
        arguments = {},
        options = {},
        fn = actualConfig.action or function(_) end,
    }

    local cmd = (
        setmetatable(self, {
            __index = CommandPrototype.prototype,
        }) :: any
    ) :: CommandPrototype

    cmd:__parser(command, cmd.positional_args)
    assert(cmd.name, 'CommandPrototype name is required')

    cmd:option('--help', nil, nil, true)

    return (cmd :: any) :: CommandPrototype
end

export type ArgumentCreatorParams = {
    name: string,
    type: string,
    default: string,
    description: string?,
}

export type Config = {
    arguments: { Argument }?,
    description: string?,
    alias: { string }?,
    positional_args: { string }?,
    hide: boolean?,
    action: ((...any) -> ())?,
    main: boolean?,
}

export type CommandPrototype = {
    name: string,
    _description: string,
    hide: boolean,
    alias: { string },
    positional_args: { string },
    arguments: { Argument },
    options: { Option },
    fn: (...any) -> (),
} & typeof(CommandPrototype.prototype)

return CommandPrototype.interface
