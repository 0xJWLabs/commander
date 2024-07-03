local __DEV__ = _G.__DEV__
local types = require("../types")
type Array<T> = types.Array<T>
type callbackFn<T> = (element: T, index: number, array: Array<T>) -> ()
type callbackFnWithThisArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> ()

return function<T, U>(array: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): ()
    if typeof(array) ~= "table" then
        error(string.format("Array.forEach called on %s", typeof(array)))
    end
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

	local k = 1

    for index, value in array do
        if thisArg ~= nil then
			(callback :: callbackFnWithThisArg<T, U>)(thisArg, value, index, array)
		else
			(callback :: callbackFn<T>)(value, index, array)
		end
    end
end