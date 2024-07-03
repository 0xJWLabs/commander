local Argument = require('./argument')
local CommandPrototye = require('./commandPrototype')
local LuauPolyfill = require('./utils/polyfill')
local Option = require('./option')
local RegExp = require('utils/regexp')

local Array = LuauPolyfill.Array
local String = LuauPolyfill.String

local Helper = {}

function Helper.optionTerm(option: Option.Option)
    return option.flags
end

function Helper.optionDescription(option: Option.Option)
    local extraInfo = {}
    if option.default ~= nil then
        Array.push(extraInfo, `(default: {option.default})`)
    end

    if #extraInfo > 0 then
        return `{option.description} {Array.join(extraInfo, ', ')}`
    end

    return option.description
end

function Helper.argumentTerm(arg: Argument.Argument)
    return arg:name()
end

function Helper.argumentDescription(arg: Argument.Argument)
    local extraInfo = {}
    if arg.default ~= nil then
        Array.push(extraInfo, `default: {arg.default}`)
    end

    if #extraInfo > 0 then
        local extraDescription = `({Array.join(extraInfo, ', ')})`
        if arg.description then
            return `{arg.description} {extraDescription}`
        end
    end

    return arg.description
end

function Helper.longestArgumentTermLength(commander, cmd): number
    return Array.reduce(cmd.arguments, function(max, arg)
        local term = commander._theme.command.option.color(Helper.argumentTerm(arg))
        return math.max(max, #term)
    end, 0)
end

function Helper.longestCommandTermLength(commander): number
    return Array.reduce(commander.commands, function(max, cmd)
        local term = Helper.commandTerm(commander, cmd) or ''
        term = commander._theme.command.definition.color(term)
        return math.max(max, #term)
    end, 0)
end

function Helper.longestOptionTermLength(commander, cmd): number
    return Array.reduce(cmd.options, function(max, opt)
        local term = commander._theme.command.option.color(Helper.optionTerm(opt))
        return math.max(max, #term)
    end, 0)
end

function Helper.padWidth(commander, cmd)
    return math.max(Helper.longestOptionTermLength(commander, cmd), Helper.longestArgumentTermLength(commander, cmd))
end

function Helper.subCommandTerm(cmd: CommandPrototye.CommandPrototype)
    local usage = cmd.name .. ' '
    if #cmd.arguments > 0 then
        for _, argument in ipairs(cmd.arguments) do
            usage = usage .. Argument.humanReadableArgName(argument) .. ' '
        end
    end
    if #cmd.options > 0 then
        usage ..= '[options]'
    else
        usage ..= ''
    end
    return usage
end

function Helper.optionTerm(option: Option.Option)
    return option.flags
end

function Helper.argumentTerm(argument: Argument.Argument)
    return argument:name()
end

function Helper.optionDescription(option: Option.Option)
    return option.description .. (not (option.default == nil) and " (default: \"" .. tostring(option.default) .. "\")" or "")
end

function Helper.commandDescription(cmd: CommandPrototye.CommandPrototype)
    return cmd._description 
end

-- function Helper.commandTerm(commander: any, cmd: CommandPrototye.CommandPrototype, flagUsage: boolean?)
--     if cmd.hide then
--         return
--     end


--     local cmdPrev = ''
--     if flagUsage then
--         cmdPrev = commander._theme.command.category.color('Usage:')
--     end
--     cmdPrev ..= ' '
--     print(
--         cmdPrev
--             .. commander._theme.command.definition.color(
--                 (commander._name and commander._name .. ' ' or '') .. Helper.subCommandTerm(cmd) 
--             )
--             .. ' => '
--             .. commander._theme.command.description.color(Helper.commandDescription(cmd))
--     )
-- end

function Helper.commandFlag(cmd: CommandPrototye.CommandPrototype): string?
    if cmd.hide then
        return
    end
    local usage = 'Usage:'

    return usage
end

function Helper.commandTerm(commander: any, cmd: CommandPrototye.CommandPrototype): string?
    if cmd.hide then
        return
    end

    local usage = ' '
    return (
        usage .. (commander._name and commander._name .. ' ' or '') .. Helper.subCommandTerm(cmd) 
    )
end

function Helper.visibleOptions(cmd: CommandPrototye.CommandPrototype): { Option.Option }
    local visibleOptions = Array.filter(cmd.options, function(opt: Option.Option)
        return not opt.hide
    end)

    return visibleOptions :: { Option.Option }
end

function Helper.formatHelp(commander: any, cmd: CommandPrototye.CommandPrototype?)
    if cmd then
        local padWidth = Helper.padWidth(commander, cmd)
        local usage = (commander :: any)._theme.command.category.color('Usage: ')
            .. (commander :: any)._theme.command.definition.color(
                (commander._name and commander._name .. ' ' or '') .. Helper.subCommandTerm(cmd) 
            ) --.." => " .. self.description .. "\n"
        usage = usage .. (commander :: any)._theme.command.category.color('\nName: ') .. cmd.name
        if #cmd.alias > 0 then
            usage = usage
                .. (commander :: any)._theme.command.category.color('; alias: ')
                .. Array.join(cmd.alias, ', ')
        end
        usage = usage .. '\n'
        if #Helper.commandDescription(cmd) > 0 then
            usage = usage
                .. (commander :: any)._theme.command.category.color('Description: ')
                .. Helper.commandDescription(cmd)
                .. '\n'
        end
        if #cmd.arguments > 0 then
            usage = usage .. (commander :: any)._theme.command.category.color('Arguments:\n')
            Array.forEach(cmd.arguments, function(argument: Argument.Argument)
                local Term = commander._theme.command.argument.color(Helper.argumentTerm(argument))
                usage ..= ' ' .. String.padEnd(Term, padWidth + 2, ' ') .. ' ' .. commander._theme.command.description.color(Helper.argumentDescription(argument)) .. '\n'
            end)
        end
        if #cmd.options > 0 then
            usage = usage .. (commander :: any)._theme.command.category.color('Options:\n')
            local optionList = Helper.visibleOptions(cmd)
            Array.forEach(optionList, function(opt: Option.Option)
                local term = commander._theme.command.option.color(Helper.optionTerm(opt))
                usage ..= ' ' .. String.padEnd(term, padWidth + 2, ' ') .. ' ' .. commander._theme.command.description.color(Helper.optionDescription(opt)) .. '\n'
            end)
        end
        print(usage)
    else
        local padWidth = Helper.longestCommandTermLength(commander)
        print(
            commander._theme.cli.title.color(
                commander._title
                    .. ' (v'
                    .. commander._version
                    .. ')'
                    .. ((#commander.author > 0 and ' by ' .. commander.author) or '')
                    .. '\n'
            )
                .. commander._theme.cli.category.color('Usage: ')
                .. commander._name
                .. ' <command> [options] '
        )
        if #commander._description > 0 then
            print(commander._theme.cli.category.color('Description: ') .. commander._description)
        end
        if commander.default_action and commander.default_action_command then
            print(
                commander._theme.cli.category.color('Default command: ')
                    .. commander.default_action_command.name
                    .. (
                        (
                            #commander.default_action_command._description > 0
                            and ' => ' .. commander.default_action_command._description
                        ) or ''
                    )
            )
        end
        commander._theme.cli.category('Commands:')
        Array.forEach(commander.commands, function(cmd)
            local term = Helper.commandTerm(commander, cmd) or ''

            print(String.padEnd(commander._theme.command.definition.color(term), padWidth + 2, ' ') .. commander._theme.command.description.color(Helper.commandDescription(cmd)))
        end)
        print()
        print(
            commander._theme.cli.category.color('Use: ')
                .. commander._theme.command.definition.color(commander._name .. ' help <command>')
                .. ' to get more info about that command'
        )
    end
end

function Helper.wrap(str: string, width: number, indent: number, minColumnWidth: number?)
    -- Default minimum column width.
    local minColumnWidth = minColumnWidth or 40

    -- Full \s characters, minus the linefeeds.
    local indents = {
        ` `,
        `\f`,
        `\t`,
        `\v`,
        `\u{00a0}`,
        `\u{1680}`,
        `\u{2000}`,
        `\u{2001}`,
        `\u{2002}`,
        `\u{2003}`,
        `\u{2004}`,
        `\u{2005}`,
        `\u{2006}`,
        `\u{2007}`,
        `\u{2008}`,
        `\u{2009}`,
        `\u{200a}`,
        `\u{202f}`,
        `\u{205f}`,
        `\u{3000}`,
        `\u{feff}`,
    }

    -- Detect manually wrapped and indented strings by searching for line break followed by spaces.
    local manualIndentPattern = '[\n][' .. table.concat(indents) .. ']+'

    if string.find(str, manualIndentPattern) then
        return str
    end

    -- Do not wrap if not enough room for a wrapped column of text (as could end up with a word per line).
    local columnWidth = width - indent
    if columnWidth < minColumnWidth then
        return str
    end


    local leadingStr = string.sub(str, 1, indent)
    local columnText = string.sub(str, indent + 1)
    columnText = string.gsub(columnText, '\r\n', '\n')
    local indentString = string.rep(' ', indent)
    local zeroWidthSpace = `\u{200B}`
    local breaks = '\\s' .. zeroWidthSpace

    -- Match line end (so empty lines don't collapse),
    -- or as much text as will fit in column, or excess text up to first break.
    local regex = RegExp(
        ('\n|.{1,%s}([%s]|$)|[^%s]+?([%s]|$)'):format(
            tostring(columnWidth - 1),
            tostring(breaks),
            tostring(breaks),
            tostring(breaks)
        )
    )

    local ref = regex:exec(columnText)

    local lines = {}
    for index, line in ref do
        if typeof(index) == 'number' then
            table.insert(lines, line)
        end
    end

    return leadingStr
        .. Array.join(
            Array.map(lines, function(line, i)
                if line == '\n' then
                    return ''
                end

                return (i > 0 and indentString or '') .. String.trimEnd(line)
            end),
            '\n'
        )
end

return Helper
