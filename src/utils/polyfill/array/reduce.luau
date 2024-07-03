local types = require("../types")
local isArray = require("isArray")

type Array<T> = types.Array<T>
type reduceFn<T, U> = (previousValue: U, currentValue: T, currentIndex: number, array: Array<T>) -> U

return function<T, U>(array: Array<T>, callback: reduceFn<T, U>, initialValue: U?): U
    if not isArray(array) then
        error(string.format("Array.reduce called on %s", typeof(array)))
    end
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

	local length = #array

	local value: T | U
	local initial = 1

	if initialValue ~= nil then
		value = initialValue
	else
		initial = 2
		if length == 0 then
			error("reduce of empty array with no initial value")
		end
		value = array[1]
	end

	for i = initial, length do
		value = callback(value :: U, array[i], i, array)
	end

	return value :: U
end