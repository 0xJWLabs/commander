local types = require("../types")

local Map = require("./map")
local coerceToMap = require("./coerceToMap")
local coerceToTable = require("./coerceToTable")

export type Map<K, V> = types.Map<K, V>

return {
	Map = Map,
	coerceToMap = coerceToMap,
	coerceToTable = coerceToTable,
}