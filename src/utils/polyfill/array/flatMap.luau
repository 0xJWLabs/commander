local flat = require('./flat')
local map = require('./map')
local types = require('../types')
type Array<T> = types.Array<T>
type callbackFn<T, U> = (element: T, index: number, array: Array<T>) -> U
type callbackFnWithThisArg<T, U, V> = (thisArg: V, element: T, index: number, array: Array<T>) -> U

local function flatMap<T, U, V>(
    array: Array<T>,
    callback: callbackFn<T, U> | callbackFnWithThisArg<T, U, V>,
    thisArg: V?
): Array<U>
    if typeof(array) ~= 'table' then
        error(string.format('Array.flatMap called on %s', typeof(array)))
    end
    if typeof(callback) ~= 'function' then
        error('callback is not a function')
    end
    return flat(map(array, callback, thisArg))
end

return flatMap
