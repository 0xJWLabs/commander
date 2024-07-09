local date = require('@lune/datetime')
local repr = require('../repr')
local Ansis = require('../ansis')

local enums = require('./enums')

local colors = enums.colors
local chars = enums.chars

local function getCurrentDTStr()
    return date.now():formatLocalTime('%d-%m-%Y %I:%M:%S %p %z')
end

local function getFullName(obj: Logger)
    local name = obj.name
    local ptr: any = obj.parent
    while ptr ~= nil do
        name = `{ptr.name}/{name}`
        ptr = ptr.parent
    end

    return name
end

local Logger = {}
Logger.prototype = {}
Logger.interface = {}
Logger.prototype._type = 'Logger'

function Logger.prototype.register(self: Logger, name: string): Logger
    local namespace = Logger.interface.new(name, self)
    table.insert(self.namespaces, namespace :: any)
    return (namespace :: any) :: Logger
end

function Logger.prototype.get(self: Logger, name: string): Logger
    for _, namespace in self.namespaces do
        if namespace.name == name then
            return (namespace :: any) :: Logger
        end
    end
    return self:register(name)
end

function Logger.prototype.write(self: Logger, types: string, message: string, ...: any): ()
    local color = colors[types].background
    local logType = string.upper(types)

    -- Get calling function's file and line information
    local name, line = debug.info(4, 'sl')
    local fileName: string = name:match('^%[string "(.-)"%]$')

    fileName = fileName:gsub('\\', '/'):gsub('^src/', '')

    local extras = { ... }

    -- Prepare the main log line
    local formattedMessage =
        string.format('%s: %s %s', logType, Ansis.dim(chars.startLine), Ansis.bold(message))
    local formattedInfo = string.format(
        '%s: %s at %s:%d [%s] - %s',
        logType,
        #extras > 0 and chars.line or chars.endLine,
        fileName,
        line,
        getFullName(self),
        getCurrentDTStr()
    )
    local messageLine = Ansis.hex(color)(formattedMessage)
    local infoLine = Ansis.hex(color)(Ansis.dim(formattedInfo))

    -- Prepare the lines to print
    local lines = { messageLine, infoLine }

    -- Add extras if any
    if #extras > 0 then
        for i = 1, select('#', ...) do
            local lineEnding = (i == #extras) and chars.endLine or chars.line
            local extra = select(i, ...)
            local type = extra['name'] or extra['title']
            local data = extra['data'] or extra['value']

            local extraLine = string.format(
                '%s [%s] %s',
                Ansis.hex(color)(Ansis.dim(logType .. ':', lineEnding)),
                type,
                repr(data, { pretty = false })
            )
            table.insert(lines, extraLine)
        end
        -- for i, extra in extras do
        --     print(extra)
        --     local lineEnding = (i == #extras) and chars.endLine or chars.line
        --     local extraLine = string.format("%s: [%d] %s", chalk.hex(color)(chalk.dim(logType, lineEnding)), i, repr(extra, { pretty = false }))
        --     table.insert(lines, extraLine)
        -- end
    end

    table.insert(lines, '')

    -- Print all lines
    print(table.concat(lines, '\r\n'))

    return
end

function Logger.prototype.getPadding(_: Logger, message: string?)
    local padding = ''
    local matches = message and { message:match('^%s+') }
    if matches and #matches > 0 then
        padding = matches[1] :: string
    end

    return padding
end

function Logger.prototype.trace(self: Logger, message: string, ...: any)
    return self:write('trace', message, ...)
end
function Logger.prototype.debug(self: Logger, message: string, ...: any)
    return self:write('debug', message, ...)
end

function Logger.prototype.info(self: Logger, message: string, ...: any)
    return self:write('info', message, ...)
end

function Logger.prototype.warn(self: Logger, message: string, ...: any)
    return self:write('warn', message, ...)
end

function Logger.prototype.error(self: Logger, message: string, ...: any)
    return self:write('error', message, ...)
end

function Logger.interface.new(name: string, root: Logger?): Logger
    return (
        setmetatable({
            name = name,
            namespaces = {},
            parent = root,
        }, {
            __index = Logger.prototype,
        }) :: any
    ) :: Logger
end

export type Logger = typeof(Logger.prototype) & {
    name: string,
    namespaces: { Logger },
    parent: Logger?,
}

return Logger.interface
