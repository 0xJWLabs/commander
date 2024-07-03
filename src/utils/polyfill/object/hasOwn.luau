--!strict

local types = require("../types")
type Array<T> = types.Array<T>
type Map<K, V> = types.Map<K, V>

return function<T>(value: string | { [string]: T } | Array<T> | Map<any, T>, key: T | string | any): boolean 
	assert(value :: any ~= nil, "cannot get hasOwn from a nil value")
	local valueType = typeof(value)

	if valueType == "table" then
		for originalKey, keyValue in pairs(value :: { [string]: T } | Array<T>) do
            if key == originalKey then
                return true
            end
		end
	elseif valueType == "string" then
		-- TODO: should we be using utf8.len?
		for i = 1, string.len(value :: string) do
            if string.sub(value :: string, i, i) == key then
                return true
            end
		end
	end

	return false
end