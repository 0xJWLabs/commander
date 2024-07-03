local isArray = require("./isArray")
local types = require("../types")
type Array<T> = types.Array<T>

return function<T>(array: Array<T>): T?
    if not isArray(array) then
        error(string.format("Array.pop called on non-array %s", typeof(array)))
    end

    return table.remove(array, #array)
end