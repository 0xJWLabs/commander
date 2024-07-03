local types = require("../types")
type Array<T> = types.Array<T>
type callbackFn<T> = (element: T, index: number, array: Array<T>) -> boolean
type callbackFnWithThisArg<T, U> = (self: U, element: T, index: number, array: Array<T>) -> boolean

return function<T, U>(array: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): boolean
    if typeof(array) ~= "table" then
        error(string.format("Array.every called on %s", typeof(array)))
    end
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

    for i, value in array do
        local testResult
        if thisArg ~= nil then
            testResult = (callback :: callbackFnWithThisArg<T, U>)(thisArg, value, i, array)
        else
            testResult = (callback :: callbackFn<T>)(value, i, array)
        end

        if not testResult then
            return false
        end
    end

	return true
end