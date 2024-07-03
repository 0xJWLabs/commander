local isArray = require("isArray")
local types = require("../types")
type Array<T> = types.Array<T>
type callbackFn<T, U> = (element: T, index: number, array: Array<T>) -> U
type callbackFnWithThisArg<T, U, V> = (thisArg: V, element: T, index: number, array: Array<T>) -> U

return function<T, U, V>(array: Array<T>, callback: callbackFn<T, U> | callbackFnWithThisArg<T, U, V>, thisArg: V?): Array<U>
    if not isArray(array) then
        error(string.format("Array.map called on %s", typeof(array)))
    end
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

	local new = {}
	local k = 1

    for i, value in array do
        local mappedValue: U
        if thisArg ~= nil then
            mappedValue = (callback :: callbackFnWithThisArg<T, U, V>)(thisArg, value, i, array)
        else
            mappedValue = (callback :: callbackFn<T, U>)(value, i, array)
        end

        if mappedValue ~= nil then
            table.insert(new, mappedValue)
        end
    end

    return new
end