local isArray = require("./isArray")
local types = require("../types")
type Array<T> = types.Array<T>

local function flatten<T>(array: Array<T>, depth: number?): Array<T>
    if not isArray(array) then
        error(string.format("Array.flat called on %s", typeof(array)))
    end
    if depth ~= nil and typeof(depth) ~= "number" then
        error("depth is not a number or nil")
    end

    local actualDepth = if depth == nil then math.huge else depth

    if actualDepth == 0 then
        return array :: Array<T>
    end

	local newArray: Array<T> = {}

	for _, v in array do
		if isArray(v) then
			local vArray = (v :: any) :: Array<T>
			local innerArrFlat: Array<T> = if depth > 1 then flatten(vArray, actualDepth - 1) else vArray
			for _, innerValue in innerArrFlat do
				table.insert(newArray, innerValue)
			end
		else
			table.insert(newArray, v)
		end
	end

	return newArray
end

return flatten