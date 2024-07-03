
local types = require("../types")
type Array<T> = types.Array<T>
type Object = types.Object

return function(t: Object | Array<any>): boolean
	return table.isfrozen(t)
end