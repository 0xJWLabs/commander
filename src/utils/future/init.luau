--!nocheck

local Result = require('./result')
local Stream = require('./stream')
local task = require('@lune/task')

local threads: { thread } = {}

local function fnPasser<T...>(fn: (T...) -> (), thread: thread, ...: T...)
    fn(...)
    table.insert(threads, thread)
end

local function yielder()
    while true do
        fnPasser(coroutine.yield())
    end
end

local function spawn<T...>(callback: (T...) -> (), ...: T...)
    local thread: thread
    if #threads > 0 then
        thread = threads[#threads]
        threads[#threads] = nil
    else
        thread = coroutine.create(yielder)
        coroutine.resume(thread)
    end

    task.spawn(thread, callback, thread, ...)
end

local Future = {}
Future.interface = {}
Future.prototype = {}
Future.prototype.__type = 'Future'

function Future.prototype.after<T..., E...>(self: Future<T...>, fn: (E...) -> T...): Result.Result<T...>
    if self.values then
        return spawn(fn, self.values.result) :: Result.Result<T...>
    else
        table.insert(self.afters, fn)
    end
    return
end

function Future.prototype.await<T...>(self: Future<T...>): Result.Result<T...>
    if self.values then
        return self.values.result :: Result.Result<T...>
    else
        table.insert(self.yields, coroutine.running())
        return coroutine.yield()
    end
end

function Future.interface.new<T..., E...>(callback: (E...) -> T..., ...: E...): Future<T...>
    local self: Future<T...> = setmetatable({
        values = nil,
        afters = {},
        yields = {},
    }, {
        __index = Future.prototype,
    }) :: any

    spawn(function(self: Future<T...>, callback: (E...) -> T..., ...: E...)
        self.values = Stream.new(callback, ...)

        for _, thread in self.yields do
            local values = self.values
            local results = (values :: Stream.Stream<T...>)()
            task.spawn(thread, results)
        end

        for _, callback in self.afters do
            local values = self.values
            local results = (values :: Stream.Stream<T...>)()
            spawn(callback, results)
        end
    end, self, callback, ...)

    return self
end

function Future.interface.try<T..., E...>(fn: (E...) -> T..., ...: E...): Future<T...>
    return Future.interface.new(function(...)
        local data = { pcall(fn, ...) }
        local success = table.remove(data, 1)

        if not success then
            error(data[1])
        end

        return table.unpack(data)
    end, ...)
end

export type Future<T...> = typeof(setmetatable(
    {} :: {
        values: Stream.Stream<T...>,
        afters: { (T...) -> T... },
        yields: { thread },
    },
    {} :: {
        __index: typeof(Future.prototype),
    }
))

return Future.interface
