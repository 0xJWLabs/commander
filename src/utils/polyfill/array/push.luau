local types = require("../types")
local isArray = require("isArray")

type Array<T> = types.Array<T>

return function<T>(array: Array<T>, ...: T?)
	if not isArray(array) then
		error(string.format("Array.push called on %s", typeof(array)))
	end

    for i = 1, select('#', ...) do
        local value = select(i, ...)
        if value ~= nil then
            table.insert(array, value)
        end
    end
end