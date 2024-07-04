local Logger = require('./utils/logger')
local Table = require("./utils/table")

type Logger = Logger.Logger

local function stringify(t: Parsed)
    t['devLogger'] = nil
    local res = {}
    local ordered = {}
    for k, _ in t :: any do
        table.insert(ordered, k)
    end

    table.sort(ordered, function(a, b)
        return tostring(a) < tostring(b)
    end)

    for _, key in ordered do
        local value = (t :: any)[key]
        if not (type(value) == 'table') then
            if value == "nil" then
                value = nil
            end
            table.insert(res, { key, value })
        else
            table.insert(res, { key, value :: any })
        end
    end
    return res
end

local Parsed = {}
Parsed.prototype = {}
Parsed.interface = {}
Parsed.prototype.__type = 'Parsed'

function Parsed.prototype.setarg(self: Parsed, key: string, value: any)
    (self :: any)[key] = value or 'nil'
end

function Parsed.prototype.print(self: Parsed)
    if self['devLogger'] then
        self.devLogger:debug('Parsed', Table.spread(stringify(self)))
    end
end

function Parsed.prototype.parse(self: Parsed)
    local data = {}
    for key, value in self :: any do
        data[key] = value ~= 'nil' and value or nil
    end

    return data
end

function Parsed.interface.new(list: any, logger: Logger?): Parsed
    list = list or {}

    if logger then
        list['devLogger'] = logger
    end
    return setmetatable(list, {
        __index = Parsed.prototype,
        __tostring = function(self)
            return stringify(self)
        end,
    })
end

export type Parsed = { [any]: any, devLogger: Logger? } & typeof(Parsed.prototype)

return function(list: any, logger: Logger?)
    return Parsed.interface.new(list, logger)
end
