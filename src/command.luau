local ArgumentModule = require('./argument')
local Helper = require('./helper')
local Option = require('./option')
local Parsed = require('./utils/parsed')
local String = require('./utils/string')
local Table = require('./utils/table')
local process = require('@lune/process')

local Config = require('./config')
local Argument = ArgumentModule.Argument

type Argument = ArgumentModule.Argument
type Option = Option.Option
type OptionParams = Option.OptionParams
type ArgumentParams = ArgumentModule.ArgumentParams

local function optlist_parser(arguments, index: number, list: any?)
    local list = list or {}
    if arguments[index] and not String.startsWith(arguments[index], '-') then
        table.insert(list, arguments[index])
        return optlist_parser(arguments, index + 1, list)
    end
    return list, index
end

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

local Command = {} 

Command.prototype = {}
Command.interface = {}

Command.prototype.__type = 'Command'

function Command.prototype.action(self: Command, fn: (...any) -> ())
    assert(fn, 'fn <function> is required for ' .. self._name .. ' command')
    self.fn = fn

    return self
end

function Command.prototype.replaceArgument(
    self: Command,
    argname: string,
    description: string?,
    default: string?
): Command
    assert(argname, 'argument for ' .. self._name .. ' command')
    for _, v in self.registeredArguments do
        if v._name == argname then
            v.description = (not (description == nil) and description) or v.description
            v.default = (not (default == nil) and default) or v.default
        end
    end

    return self
end

function Command.prototype.hasOpt(self: Command, opt: string): Option?
    return Table.find(self.options, function(value)
        if value.long == opt or value.short == opt then
            return true
        end

        return false
    end)
end

function Command.prototype.names(self: Command)
    local names = { self._name }
    for _, alias in self._aliases do
        table.insert(names, alias)
    end

    return names
end

function Command.prototype.description(
    self: Command,
    description: string
): Command
    self._description = description

    return self
end

function Command.prototype.option(
    self: Command,
    flags: string,
    description: string?,
    default: any?,
    hidden: boolean?,
    transform: ((...any) -> ())?
): Command
    local flagSplit = splitOptionFlags(flags)

    local config = {
        flags = flags,
        description = description,
        transform = transform,
        type = flagSplit.optType,
        default = default,
        hidden = hidden,
    }

    local option = self:optionCreator(config)
    table.insert(self.options, option)
    table.sort(self.options, function(a, b)
        return a:name() < b:name()
    end)

    return self
end

function Command.prototype.run(self: Command, ...: any)
    return self.fn(...)
end

function Command.prototype.aliases(self: Command, alias: string | { string })
    assert(
        type(alias) == 'table' or type(alias) == 'string',
        'Alias should be a table (like-array) or a string'
    )
    if type(alias) == 'table' then
        self._aliases = alias
    else
        self._aliases = { alias }
    end
    return self
end

function Command.prototype.usage(self: Command): string
    local args = Table.map(self.registeredArguments, function(arg)
        return ArgumentModule.humanReadableArgName(arg)
    end)

    local fixedTable = Table.concat(
        {},
        #self.commands > 0 and '[command]' or {},
        #self.registeredArguments > 0 and args or {},
        #self.options > 0 and '[options]' or {}
    )

    return table.concat(fixedTable, ' ')
end

function Command.prototype.argument(
    self: Command,
    argument: string,
    description: string?,
    default: string?
)
    local word = string.match(argument, '[%w_-]+') :: string
    if argument == '<' .. word .. '>' then
        table.insert(
            self.registeredArguments,
            self:argumentCreator({
                name = argument,
                type = 'req',
                description = description,
                default = default,
            })
        )
    elseif argument == '[' .. word .. ']' then -- Optional arguments
        table.insert(
            self.registeredArguments,
            self:argumentCreator({
                name = argument,
                type = 'opt',
                description = description,
                default = default,
            })
        )
    elseif argument == '[' .. word .. '...]' or argument == '[...' .. word .. ']' then -- Optional List arguments
        table.insert(
            self.registeredArguments,
            self:argumentCreator({
                name = argument,
                type = 'optlist',
                description = description,
                default = default,
            })
        )
    else
        error('Defining command argument. command: ' .. self._name .. ' word: ' .. word)
    end

    return self
end

function Command.prototype.checkParsed(self: Command, parsed)
    local required: { { name: string, type: string, typearg: string } } =
        {} :: { { name: string, type: string, typearg: string } }
    if #self.registeredArguments > 0 then -- Parse required and optional arguments
        for _, cmd_arg in ipairs(self.registeredArguments) do
            if parsed[cmd_arg:name()] == nil and cmd_arg.required then
                table.insert(
                    required,
                    { name = cmd_arg:name(), type = cmd_arg.type :: string, typearg = 'argument' }
                )
            end
        end
    end
    local err = 'Default action has required arguments what are not defined: '
    for _, value in required do
        err ..= value.name .. ', '
    end

    if not (#required == 0) then
        error(err)
    end
    return (#required == 0)
end

function Command.prototype.__parser(self: Command, command: string, defaults: any)
    local result = {}
    defaults = defaults or {}
    local inputs = String.split(command, '%s+')
    for index, input in inputs do
        local word = string.match(input, '[%w_-]+') :: string
        local config = defaults[word]
        if not (typeof(config) == 'table') then
            config = { description = (type(config) == 'string' and config) or '', default = nil }
        end

        if word == input and index == 1 then
            self._name = word
        elseif input == '<' .. word .. '>' then
            table.insert(
                self.registeredArguments,
                self:argumentCreator({
                    name = input,
                    type = 'req',
                    description = config.description,
                    default = config.default,
                })
            )
        elseif input == '[' .. word .. ']' then -- Optional arguments
            table.insert(
                self.registeredArguments,
                self:argumentCreator({
                    name = input,
                    type = 'opt',
                    description = config.description,
                    default = config.default,
                })
            )
        elseif input == '[' .. word .. '...]' or input == '[...' .. word .. ']' then -- Optional List arguments
            table.insert(
                self.registeredArguments,
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
    end

    return result
end

function Command.prototype.argumentCreator(
    _: Command,
    options: ArgumentParams
): Argument
    local argument = Argument.new(options)
    return argument
end

function Command.prototype.optionCreator(
    _: Command,
    options: OptionParams
): Option
    local option = Option.new(options)
    return option
end

function Command.prototype.findCmd(
    self: Command,
    cmd: string | { string }
): Command?
    local actualCmdName = (typeof(cmd) == 'string' and { cmd } or cmd) :: { string }
    return Table.find(self.commands, function(command)
        local res = false
        for _, cmdName in actualCmdName do
            if command._name == cmdName or table.find(command._aliases, cmdName) then
                res = true
            end
        end

        return res
    end)
end

function Command.prototype.command(
    self: Command,
    command: string | Command,
    description: (string | Command)?,
    _config: Config?
): Command
    if typeof(command) == 'string' then
        local config: Config?

        if description ~= nil then
            if type(description) == 'table' then
                config = description :: any
            end
            if type(description) == 'string' then
                config = _config or {};
                (config :: Config).description = description
            end
        end

        local cmd = Command.interface.new(command, config)
        cmd.parent = self
        local cmdSetted = self:findCmd(cmd:names())
        if cmdSetted then
            error('')
        end

        table.insert(self.commands, cmd)
        table.sort(self.commands, function(a, b)
            return a._name < b._name
        end)

        return cmd
    else
        local cmd = command
        local cmdSetted = self:findCmd(cmd:names())
        if cmdSetted then
            error('')
        end

        table.insert(self.commands, cmd)
        table.sort(self.commands, function(a, b)
            return a._name < b._name
        end)

        return cmd
    end
end

function Command.prototype.parse(self: Command, message: { string }?)
    self:__parser(self._name, self.positional_args)
    local args: { string } = message and table.clone(message) or table.clone(process.args)

    local parsed = Parsed(args, nil)

    

    if not (parsed :: any)[1] then
        self:run()
    else
        local cmd: Command = self:findCmd(args[1]) or self

        if cmd.parent == nil then
            cmd:option('--version', nil, false, true)
        end

        parsed:setarg('_cmd', cmd._name)

        local indexarg = self:findCmd(args[1]) and 2 or 1
        if #cmd.registeredArguments > 0 then -- Parse required and optional arguments
            for _, cmd_arg in ipairs(cmd.registeredArguments) do
                (parsed :: any)[cmd_arg:name()] = cmd_arg.default
                    or (cmd_arg.variadic and {})
                    or nil
                if args[indexarg] and not String.startsWith(args[indexarg], '-') then
                    if cmd_arg.variadic then
                        (parsed :: any)[cmd_arg:name()], indexarg = optlist_parser(args, indexarg)
                    else
                        -- parsed[cmd_arg:name()] = args[indexarg]
                        parsed:setarg(cmd_arg:name(), args[indexarg])
                        indexarg = indexarg + 1
                    end
                else
                    if cmd_arg.required then -- if required argument is missing, then execute Commander:usage() to show help usage
                        print('A')
                        -- local usage = Helper.commandFlag(cmd) or ''
                        -- if usage then
                        --     usage = self._theme.command.category.color('Usage:')
                        -- end
                        -- local term = Helper.commandTerm(self, cmd)
                        -- if term then
                        --     usage ..= self._theme.command.definition.color(term)
                        -- end

                        -- return usage
                        --     .. self._theme.command.description.color(
                        --         Helper.commandDescription(cmd)
                        --     )
                    end
                end
            end
        end
        for ka = indexarg, #args do -- Parse flags arguments
            local a = args[ka]
            local opt = cmd:hasOpt(a)
            if opt then
                if opt.type == 'normal' then
                    if args[ka + 1] and not String.startsWith(args[ka + 1], '-') then
                        parsed:setarg(opt:attributeName(), opt.transform(args[ka + 1]))
                        ka = ka + 2
                    else
                        parsed.help = true
                        -- Helper.formatHelp(self, cmd)
                    end
                else
                    parsed:setarg(opt:attributeName(), true)
                end
            end
        end

        -- Add default opt to parsed table if that opt is nil (not defined)
        for _, opt in cmd.options do
            if (parsed :: any)[opt:attributeName()] == nil then
                parsed:setarg(opt:attributeName(), opt.default)
            end
        end

        parsed:print()

        if parsed.help == true then
            Helper.formatHelp(cmd)
        elseif parsed.version == true then
            print('Yes')
        else
            local parsedData = parsed:parse()
            cmd:run(parsedData, cmd, self)
        end
    end

    process.exit(0)

    return parsed
end

function Command.prototype.name(self: Command, name: string)
    self._name = name

    return self
end

function Command.interface.new(command: string?, config: Config?): Command
    local actualConfig: Config = config or {} :: Config
    actualConfig.arguments = (actualConfig.arguments or {}) :: any

    local self = {
        _name = command,
        _description = actualConfig.description or '',
        hidden = (not (actualConfig.hidden == nil) and actualConfig.hidden) or false,
        _aliases = actualConfig.alias or {},
        positional_args = actualConfig.positional_args or {},
        registeredArguments = {},
        options = {},
        commands = {},
        fn = actualConfig.action or function(_) end,
        parent = nil,
    }

    local cmd = (
        setmetatable(self, {
            __index = Command.prototype,
        }) :: any
    ) :: Command

    -- cmd:__parser(command, cmd.positional_args)
    -- assert(cmd.name, 'Command name is required')

    cmd:option('--help', nil, false, true)

    return (cmd :: any) :: Command
end

function Command.interface.setTheme(theme: string): ()
    Config.Theme = theme
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
    hidden: boolean?,
    action: ((...any) -> ())?,
    main: boolean?,
}

export type Command = {
    _name: string,
    _description: string,
    hidden: boolean,
    _aliases: { string },
    positional_args: { string },
    registeredArguments: { Argument },
    options: { Option },
    commands: { Command },
    fn: (...any) -> (),
    parsed: any?,
    parent: Command?,
} & typeof(Command.prototype)

return Command.interface
