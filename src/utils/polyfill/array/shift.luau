local isArray = require("./isArray")
local types = require("../types")
type Array<T> = types.Array<T>

return function<T>(value: Array<T>): T?
    if not isArray(value) then
        error(string.format("Array.shift called on non-array %s", typeof(value)))
    end

	if #value > 0 then
		return table.remove(value, 1)
	else
		return nil
	end
end