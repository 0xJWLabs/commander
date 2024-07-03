local Symbol = require("symbol")
local types = require("../types")

type Symbol = types.Symbol

local GlobalRegistry: { [string]: Symbol } = {}

return {
	getOrInit = function(name: string): Symbol
		if GlobalRegistry[name] == nil then
			GlobalRegistry[name] = Symbol.new(name)
		end

		return GlobalRegistry[name]
	end,
	-- Used for testing
	__clear = function()
		GlobalRegistry = {}
	end,
}