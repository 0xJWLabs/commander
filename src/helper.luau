local Argument = require('./argument')
local Chalk = require('./utils/chalk')
local Config = require('./config')
local Option = require('./option')
local String = require('./utils/string')
local Table = require('./utils/table')
local ThemeColor = require('./colors/themeColor')
local Themes = require('./colors/themes')

local Helper = {}

function Helper.optionTerm(option: Option.Option)
    return option.flags
end

function Helper.optionDescription(option: Option.Option)
    local extraInfo = {}
    if option.default ~= nil then
        table.insert(extraInfo, `(default: {option.default})`)
    end

    if #extraInfo > 0 then
        return `{option.description} {table.concat(extraInfo, ', ')}`
    end

    return option.description
end

function Helper.argumentTerm(arg: Argument.Argument)
    return arg:name()
end

function Helper.argumentDescription(arg: Argument.Argument)
    local extraInfo = {}
    if arg.default ~= nil then
        table.insert(extraInfo, `default: {arg.default}`)
    end

    if #extraInfo > 0 then
        local extraDescription = `({table.concat(extraInfo, ', ')})`
        if arg.description then
            return `{arg.description} {extraDescription}`
        end
    end

    return arg.description
end

function Helper.longestArgumentTermLength(cmd): number
    local theme = Helper.getTheme() :: any
    return Table.reduce(Helper.visibleArguments(cmd), function(max, arg)
        local term = theme.command.argument.color(Helper.argumentTerm(arg))
        return math.max(max, #term)
    end, 0)
end

function Helper.longestSubcommandTermLength(cmd): number
    local theme = Helper.getTheme() :: any
    return Table.reduce(Helper.visibleCommands(cmd), function(max, cmd)
        local term = theme.command.definition.color(Helper.subCommandTerm(cmd)) or ''
        return math.max(max, #term)
    end, 0)
end

function Helper.longestOptionTermLength(cmd): number
    local theme = Helper.getTheme() :: any
    return Table.reduce(Helper.visibleOptions(cmd), function(max, opt)
        local term = theme.command.option.color(Helper.optionTerm(opt))
        return math.max(max, #term)
    end, 0)
end

function Helper.padWidth(cmd)
    return math.max(
        Helper.longestOptionTermLength(cmd),
        Helper.longestSubcommandTermLength(cmd),
        Helper.longestArgumentTermLength(cmd)
    )
end

function Helper.subCommandTerm(cmd: any)
    local args = table.concat(
        Table.map(cmd.registeredArguments, function(arg)
            return Argument.humanReadableArgName(arg)
        end),
        ' '
    )

    return cmd._name
        .. (cmd._aliases[1] and '|' .. cmd._aliases[1] or '')
        .. (#cmd.options > 0 and ' [options]' or '')
        .. (args and ' ' .. args or '')
end

function Helper.subCommandDescription(cmd: any)
    return cmd._description
end

function Helper.optionTerm(option: Option.Option)
    return option.flags
end

function Helper.argumentTerm(argument: Argument.Argument)
    return argument:name()
end

function Helper.optionDescription(option: Option.Option)
    return option.description
        .. (
            not (option.default == nil) and ' (default: "' .. tostring(option.default) .. '")'
            or ''
        )
end

function Helper.commandDescription(cmd: any)
    return cmd._description
end

function Helper.commandFlag(cmd: any): string?
    if cmd.hidden then
        return
    end
    local usage = 'Usage:'

    return usage
end

function Helper.commandTerm(commander: any, cmd: any): string?
    if cmd.hidden then
        return
    end

    local usage = ' '
    return (
        usage
        .. (commander._name and commander._name .. ' ' or '')
        .. Helper.subCommandTerm(cmd)
    )
end

function Helper.commandUsage(cmd: any): string?
    local cmdName = cmd._name
    if cmd._aliases[1] then
        cmdName ..= '|' .. cmd._aliases[1]
    end
    local ancestorCmdNames = ''
    local ancestorCmd = cmd.parent
    while ancestorCmd do
        ancestorCmdNames = ancestorCmd._name .. ' ' .. ancestorCmdNames
        ancestorCmd = ancestorCmd.parent
    end

    local theme = Helper.getTheme() :: any

    return theme.command.definition.color(ancestorCmdNames .. cmdName .. ' ' .. cmd:usage())
end

function Helper.visibleOptions(cmd: any): { Option.Option }
    local visibleOptions = Table.filter(cmd.options, function(opt: Option.Option)
        return not opt.hidden
    end)

    return visibleOptions :: { Option.Option }
end

function Helper.visibleArguments(cmd: any)
    if
        Table.find(cmd.registeredArguments, function(argument)
            return argument.description
        end)
    then
        return cmd.registeredArguments
    end

    return {}
end

function Helper.visibleCommands(cmd: any)
    local visibleCommands = Table.filter(cmd.commands, function(cmd)
        return not cmd.hidden
    end)

    return visibleCommands
end

function Helper.formatHelp(cmd: any)
    local theme = Helper.getTheme() :: any
    local termWidth = Helper.padWidth(cmd)
    local itemIndentWidth = 2
    local itemSeparatorWidth = 2

    local function formatItem(term: string, description: string?)
        if description then
            local fullText = `{String.padEnd(term, termWidth + itemSeparatorWidth)}{description}`

            return fullText
        end

        return term
    end

    local function addIndentation(textArray)
        local indent = string.rep(' ', itemIndentWidth)
        local result = {}
        for _, line in ipairs(textArray) do
            table.insert(result, indent .. line)
        end
        return table.concat(result, '\n')
    end

    local function formatList(textArray: Table.Table<string>)
        return addIndentation(textArray)
    end

    local categoryColor = cmd.parent and theme.command.category or theme.cli.category

    local output = {}

    if not cmd.parent then
        output = { `{theme.cli.title.color(theme.cli.title.style(Config.Title))}`, '' }
        Table.concat(output, { `{categoryColor.color(`Usage:`)} {Helper.commandUsage(cmd)}`, '' })
    else
        output = { `{categoryColor.color(`Usage:`)} {Helper.commandUsage(cmd)}`, '' }
    end

    local commandDescription = Helper.commandDescription(cmd)
    if #commandDescription > 0 then
        output = Table.concat(output, {
            Helper.commandDescription(cmd),
            '',
        })
    end

    local argumentList = Table.map(Helper.visibleArguments(cmd), function(arg)
        return formatItem(
            theme.command.argument.color(Helper.argumentTerm(arg)),
            Helper.argumentDescription(arg)
        )
    end)

    if #argumentList > 0 then
        output = Table.concat(
            output,
            { `{categoryColor.color(`Arguments:`)}`, formatList(argumentList), '' }
        )
    end

    local optionList = Table.map(Helper.visibleOptions(cmd), function(opt)
        return formatItem(
            theme.command.option.color(Helper.optionTerm(opt)),
            Helper.optionDescription(opt)
        )
    end)

    if #optionList > 0 then
        output = Table.concat(
            output,
            { `{categoryColor.color(`Options:`)}`, formatList(optionList), '' }
        )
    end

    local commandList = Table.map(Helper.visibleCommands(cmd), function(cmd)
        return formatItem(
            theme.command.definition.color(Helper.subCommandTerm(cmd)),
            Helper.subCommandDescription(cmd)
        )
    end)

    if #commandList > 0 then
        output = Table.concat(
            output,
            { `{categoryColor.color(`Commands:`)}`, formatList(commandList), '' }
        )
    end

    local result = table.concat(output, '\n')

    print(result)

    return result
end

function Helper.getTheme()
    local function IsHex(str: string): boolean
        if typeof(str) ~= 'string' then
            return false
        end

        str = str:gsub('#', '')

        return string.match(str, `^%x%x%x%x%x%x$`) ~= nil
    end

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

    local theme = Themes[Config.Theme]

    local default_color = Chalk.white

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

    local function createColor(
        color: string | { color: string, style: string }
    ): ThemeColor.ThemeColor
        if typeof(color) == 'string' then
            local colorize = IsHex(color) and Chalk.hex(color) or Chalk[color] or default_color
            return ThemeColor(colorize)
        else
            local colorize = IsHex(color.color) and Chalk.hex(color.color)
                or Chalk[color.color]
                or default_color
            local style = Chalk[color.style]

            return ThemeColor(colorize, style)
        end
    end

    local newTheme = createTheme(base :: any, theme, function(value)
        return createColor(value :: any) :: any
    end)

    return newTheme
end

return Helper
