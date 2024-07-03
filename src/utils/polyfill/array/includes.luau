local types = require("../types")
local indexOf = require("./indexOf")
type Array<T> = types.Array<T>

return function<T>(array: Array<T>, searchElement: T, fromIndex: number?): boolean
	return indexOf(array, searchElement, fromIndex) ~= -1
end