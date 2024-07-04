local CommandPrototype = require('./commandPrototype')
local Parsed = require('./parsed')
local ThemeColor = require('./themeColor')
local chalk = require('./utils/chalk')
local process = require('@lune/process')
local Helper = require("./helper")
local Logger = require("./utils/logger")
local Themes = require("./themes")

local Table = require("./utils/table")
local String = require("./utils/string")


local Commander = {}

Commander.prototype = {}
Commander.interface = {}

Commander.prototype.__type = 'Commander'

local function optlist_parser(arguments, index: number, list: any?)
    local list = list or {}
    if arguments[index] and not String.startsWith(arguments[index], '-') then
        table.insert(list, arguments[index])
        return optlist_parser(arguments, index + 1, list)
    end
    return list, index
end

function Commander.prototype.action(
    self: Commander,
    cmd: CommandPrototype.CommandPrototype | string,
    params: any
): Commander
    if type(cmd) == 'string' then
        cmd = self:findCmd(cmd) :: any
    end
    params = params or {}

    local cmd = cmd :: CommandPrototype.CommandPrototype
    if cmd:checkParsed(params) then
        self.default_action = function()
            cmd:run(params, cmd, self)
        end
        self.default_action_command = cmd
    end

    return self
end

function Commander.prototype.command(
    self: Commander,
    command: string | CommandPrototype.CommandPrototype,
    description: (string | CommandPrototype.Config)?,
    _config: CommandPrototype.Config?
): CommandPrototype.CommandPrototype
    if typeof(command) == 'string' then
        local config: CommandPrototype.Config?

        if description ~= nil then
            if type(description) == 'table' then
                config = description
            end
            if type(description) == 'string' then
                config = _config or {};
                (config :: CommandPrototype.Config).description = description
            end
        end

        local cmd = CommandPrototype.new(command, config)
        local cmdSetted = self:findCmd(cmd:names())
        if cmdSetted then
            error('')
        end

        table.insert(self.commands, cmd)
        table.sort(self.commands, function(a, b)
            return a.name < b.name
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
            return a.name < b.name
        end) 

        return cmd
    end
end

function Commander.prototype.findCmd(
    self: Commander,
    cmd: string | { string }
): CommandPrototype.CommandPrototype?
    local actualCmdName = (typeof(cmd) == 'string' and { cmd } or cmd) :: { string }
    return Table.find(self.commands, function(command)
        local res = false
        for _, cmdName in actualCmdName do
            if command.name == cmdName or table.find(command.alias, cmdName) then
                res = true
            end
        end

        return res
    end)
end

function Commander.prototype.help(self: Commander, ignore_flag: boolean?)
    if self.prevent_help and not ignore_flag then
        return
    end
    Helper.formatHelp(self)
end

local function IsHex(str: string): boolean
    if typeof(str) ~= 'string' then
        return false
    end

    str = str:gsub('#', '')

    return string.match(str, `^%x%x%x%x%x%x$`) ~= nil
end

function Commander.prototype.applyTheme(self: Commander, theme: any)
    local base = {
        cli = {
            title = '',
            text = '',
            category = '',
        },
        command = {
            definition = '',
            description = '',
            argument = '',
            option = '',
            category = '',
        },
        primary = '',
        secondary = '',
        success = '',
        warning = '',
        error = '',
    }

    theme = theme

    local default_color = chalk.white

    local function createTheme(base, theme, fn)
        for index, value in base do
            if typeof(value) == 'string' then
                base[index] = fn(theme[index], index, base)
            elseif typeof(value) == 'table' then
                base[index] = createTheme(base[index], theme[index], fn)
            end
        end

        return base
    end

    local function createColor(color: string): ThemeColor.ThemeColor
        local colorize = IsHex(color) and chalk.hex(color) or chalk[color] or default_color
        return ThemeColor(colorize, color)
    end

    self._theme = createTheme(base :: any, theme, function(value)
        return createColor(value :: any) :: any
    end)

    return self
end

function Commander.prototype.print(_: Commander, ...)
    local fn = ...
    if type(fn) == 'function' then
        fn()
    else
        print(...)
    end
end

function Commander.prototype.run(self: Commander)
    self.default_action()
    return self
end

function Commander.prototype.parse(self: Commander, message: { string }?)
    local args: { string } = message and table.clone(message) or table.clone(process.args)

    local parsed = Parsed(args, self.debug and Logger.new('Commander') or nil)

    if not (parsed :: any)[1] then
        self:run()
    else
        local cmd = self:findCmd(args[1])
        if not cmd then
            self:run()
        else
            parsed:setarg('_cmd', cmd.name)

            local indexarg = 2
            if #cmd.arguments > 0 then -- Parse required and optional arguments
                for _, cmd_arg in ipairs(cmd.arguments) do
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
                            local usage = Helper.commandFlag(cmd) or ''
                            if usage then
                                usage = self._theme.command.category.color('Usage:')
                            end
                            local term = Helper.commandTerm(self, cmd)
                            if term then
                                usage ..= self._theme.command.definition.color(term)
                            end

                            return usage .. self._theme.command.description.color(Helper.commandDescription(cmd))
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
                if opt:attributeName() ~= 'help' then
                    if (parsed :: any)[opt:attributeName()] == nil then
                        parsed:setarg(opt:attributeName(), opt.default)
                    end
                end
            end

            parsed:print() 

            if parsed.help then
                Helper.formatHelp(self, cmd)
            else
                local parsedData = parsed:parse()
                cmd:run(parsedData, cmd, self)
            end
        end
    end

    self.parsed = parsed

    return parsed
end

function Commander.prototype.title(self: Commander, title: string)
    self._title = title

    return self
end

function Commander.prototype.name(self: Commander, name: string)
    self._name = name

    return self
end

function Commander.prototype.description(self: Commander, description: string)
    self._description = description

    return self
end

function Commander.prototype.version(self: Commander, version: string)
    self._version = version

    return self
end

function Commander.prototype.theme(self: Commander, theme: string | ThemeConfig)
    if typeof(theme) == 'string' then
        theme = Themes[theme]
    end

    self:applyTheme(theme)

    return self
end

function Commander.interface.new(name: string?, title: string?, opt: CommanderSetupOptions?)
    local setup = opt or {} :: CommanderSetupOptions

    if not setup.debug then
        setup.debug = false
    end

    local config: CommanderSetup = {
        _title = title or '',
        _name = name or '',
        _description = setup.description and setup.description or '',
        _version = setup.version or '0.1.0',
        author = setup.author or '',
        root_path = setup.root_path or process.cwd,
        prevent_help = false,
        default_action = nil,
        commands = {},
        debug = setup.debug :: boolean 
    }


    local commander = (
        setmetatable(config, {
            __index = Commander.prototype,
        }) :: any
    ) :: Commander

    local theme: string | ThemeConfig
    if setup.theme == nil then
        theme = 'default'
    else
        theme = setup.theme
    end

    commander:theme(theme)

    local default_action = commander
        :command('help [cmd]', 'Help command')
        :action(function(parsed, _)
            if parsed.cmd then
                local command = commander:findCmd(parsed.cmd)
                if command then
                    Helper.formatHelp(commander, command)
                else
                    commander:help(true)
                end
            else
                commander:help(true)
            end
        end)

    commander:action(default_action, {})

    commander:command('--version', 'Version', { alias = { '-v' } }):action(function(_, _, com)
        com._theme.cli.text(commander._name .. ': ' .. commander._version)
    end)

    return commander :: Commander
end

export type CommanderSetupOptions = {
    description: string?,
    version: string?,
    author: string?,
    root_path: string?,
    prevent_help: boolean?,
    theme: (ThemeConfig | string)?,
    debug: boolean?,
}

export type CommanderSetup = {
    _name: string,
    _title: string,
    _description: string,
    _version: string,
    author: string,
    root_path: string,
    prevent_help: boolean,
    default_action: any,
    commands: { CommandPrototype.CommandPrototype },
    debug: boolean,
}

export type Commander = {
    _name: string,
    _title: string,
    _description: string,
    _version: string,
    author: string,
    root_path: string,
    prevent_help: boolean,
    default_action: any,
    commands: { CommandPrototype.CommandPrototype },
    _theme: any,
    default_action_command: CommandPrototype.CommandPrototype,
    parsed: any,
    debug: boolean,
} & typeof(Commander.prototype)

export type ThemeConfig = {
    cli: {
        title: string,
        text: string,
        category: string,
    },
    command: {
        definition: string,
        description: string,
        argument: string,
        option: string,
        category: string,
    },
    primary: string,
    secondary: string,
    success: string,
    warning: string,
    error: string,
}

return Commander.interface
