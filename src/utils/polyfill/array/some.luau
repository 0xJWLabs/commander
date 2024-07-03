local types = require("../types")
type Array<T> = types.Array<T>

type callbackFn<T> = (element: T, index: number, array: Array<T>) -> boolean
type callbackFnWithThisArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> boolean

return function<T, U>(t: Array<T>, callback: callbackFn<T> | callbackFnWithThisArg<T, U>, thisArg: U?): boolean
	if typeof(t) ~= "table" then
		error(string.format("Array.some called on %s", typeof(t)))
	end
	if typeof(callback) ~= "function" then
		error("callback is not a function")
	end

	for i, value in t do
		if thisArg ~= nil then
			if value ~= nil and (callback :: callbackFnWithThisArg<T, U>)(thisArg, value, i, t) then
				return true
			end
		else
			if value ~= nil and (callback :: callbackFn<T>)(value, i, t) then
				return true
			end
		end
	end
	return false
end