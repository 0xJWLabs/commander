--!strict
--[[
	A 'Symbol' is an opaque marker type, implemented to behave similarly to JS:
	https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Symbol
]]
local Symbol = require("symbol")
local types = require("../types")

export type Symbol = types.Symbol
local GlobalRegistry = require("registry.global")

local SymbolObject = setmetatable({}, {
	--[[
		Creates a new symbol, using the given name when printed. Symbols are
		opaque, so this will always create a new, unique object
	]]
	__call = function(_, name: string?): Symbol
		return Symbol.new(name)
	end,
})

SymbolObject.for_ = GlobalRegistry.getOrInit

return SymbolObject