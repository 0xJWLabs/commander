local None = require("../object/none")
local types = require("../types")

type Array<T> = types.Array<T>
type Comparable<T> = (T, T) -> boolean
local defaultSort = function<T>(a: T, b: T): boolean
	return type(a) .. tostring(a) < type(b) .. tostring(b)
end

return function<T>(array: Array<T>, compare: Comparable<T>?): Array<T>
	-- wrapperCompare interprets compare return value to be compatible with Lua's table.sort
	local wrappedCompare = defaultSort
	if compare ~= nil and compare ~= None then
		if typeof(compare :: any) ~= "function" then
			error("invalid argument to Array.sort: compareFunction must be a function")
		end
		wrappedCompare = function<T>(a: T, b: T)
			local result = compare(a :: any, b :: any)
			if typeof(result) ~= "boolean" then
				error(("invalid result from compare function, expected boolean but got %s"):format(typeof(result)))
			end
			return result
		end
	end
	table.sort(array, wrappedCompare)
	return array
end