local Argument = require('./argument')
local CommandPrototye = require('./commandPrototype')
local Option = require('./option')
local Table = require('./utils/table')
local String = require("./utils/string")

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

function Helper.longestArgumentTermLength(commander, cmd): number
    return Table.reduce(cmd.arguments, function(max, arg)
        local term = commander._theme.command.option.color(Helper.argumentTerm(arg))
        return math.max(max, #term)
    end, 0)
end

function Helper.longestCommandTermLength(commander): number
    return Table.reduce(commander.commands, function(max, cmd)
        local term = Helper.commandTerm(commander, cmd) or ''
        term = commander._theme.command.definition.color(term)
        return math.max(max, #term)
    end, 0)
end

function Helper.longestOptionTermLength(commander, cmd): number
    return Table.reduce(cmd.options, function(max, opt)
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
    local visibleOptions = Table.filter(cmd.options, function(opt: Option.Option)
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
                .. table.concat(cmd.alias, ', ')
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
            for _, argument in cmd.arguments do
                local Term = commander._theme.command.argument.color(Helper.argumentTerm(argument))
                usage ..= ' ' .. String.padEnd(Term, padWidth + 2, ' ') .. ' ' .. commander._theme.command.description.color(Helper.argumentDescription(argument)) .. '\n'
            end
        end
        if #cmd.options > 0 then
            usage = usage .. (commander :: any)._theme.command.category.color('Options:\n')
            local optionList = Helper.visibleOptions(cmd)
            for _, opt in optionList do
                local term = commander._theme.command.option.color(Helper.optionTerm(opt))
                usage ..= ' ' .. String.padEnd(term, padWidth + 2, ' ') .. ' ' .. commander._theme.command.description.color(Helper.optionDescription(opt)) .. '\n'
            end
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
        for _, cmd in commander.commands do
            local term = Helper.commandTerm(commander, cmd) or ''

            print(String.padEnd(commander._theme.command.definition.color(term), padWidth + 2, ' ') .. commander._theme.command.description.color(Helper.commandDescription(cmd)))
        end
        print()
        print(
            commander._theme.cli.category.color('Use: ')
                .. commander._theme.command.definition.color(commander._name .. ' help <command>')
                .. ' to get more info about that command'
        )
    end
end

return Helper
