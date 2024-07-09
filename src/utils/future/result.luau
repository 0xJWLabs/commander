--!nocheck

local repr = require('./repr')

local Result = {}
Result.prototype = {}
Result.interface = {}
Result.prototype.__type = 'Result'

local function assertion<T...>(self: Result<T...>, message: string?)
    assert(self.ok, message and `{message}:{self.value[1]}` or tostring(self.value[1]))
end

local function new<T...>(ok: boolean, ...: T...): Result<T...>
    local self = {
        ok = ok,
        value = {},
        _stringValue = {},
    }

    for i = 1, select('#', ...) do
        local val = select(i, ...)
        table.insert(self.value, val)
        table.insert(self._stringValue, repr(val, { colors = true }))
    end

    return (
        setmetatable(self, {
            __index = Result.prototype,
            __type = `Result<{ok and 'Ok' or 'Error'}>`,
            __tostring = function()
                return ok and `Ok<{table.concat(self._stringValue, ', ')}>`
                    or `Err<{table.concat(self._stringValue, ', ')}>`
            end,
        }) :: any
    ) :: Result<T...>
end

function Result.prototype.is_ok<T...>(self: Result<T...>): boolean
    return self.ok
end

function Result.prototype.is_err<T...>(self: Result<T...>): boolean
    return not self.ok
end

function Result.prototype.unwrap<T...>(self: Result<T...>): T...
    assertion(self)
    return table.unpack(self.value :: any)
end

function Result.prototype.expect<T...>(self: Result<T...>, message: string): T...
    assertion(self, message)

    return table.unpack(self.value :: any)
end

function Result.interface.Ok<T...>(...: T...): Result<T...>
    return new(true, ...)
end

function Result.interface.Err<T...>(...: T...): Result<T...>
    return new(false, ...)
end

export type Result<T...> = {
    ok: boolean,
    value: { any },

    is_ok: (self: Result<T...>) -> boolean,
    is_err: (self: Result<T...>) -> boolean,

    unwrap: (self: Result<T...>) -> T...,

    expect: (self: Result<T...>, message: string) -> T...,
}

return Result.interface
