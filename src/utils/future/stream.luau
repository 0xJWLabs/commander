local Result = require('./result')

local Stream = {}
Stream.interface = {}
Stream.prototype = {}
Stream.prototype.__type = 'Stream'

function Stream.prototype.poll<T...>(self: Stream<T...>)
    if not self.result then
        return false
    end
    return true
end

function Stream.interface.new<T..., E...>(callback: (E...) -> T..., ...: E...): Stream<T...>
    local ok, results = xpcall(function(...)
        return { callback(...) }
    end, function(err)
        return { err }
    end, ...)

    
    local self = {
        result = ok and Result.Ok(table.unpack(results)) or Result.Err(table.unpack(results))
    }

    return setmetatable(self, {
        __index = Stream.prototype,
        __call = function(self: Stream<T...>): Result.Result<T...>
            return self.result
        end
    })
end

export type Stream<T...> = typeof(setmetatable({} :: {
    result: Result.Result<T...>
}, {} :: {
    __index: typeof(Stream.prototype),
    __call: (self: Stream<T...>) -> Result.Result<T...>
}))

return Stream.interface