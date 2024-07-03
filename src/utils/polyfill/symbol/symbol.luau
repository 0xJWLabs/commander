local types = require("../types")

type Symbol = types.Symbol

return {
	new = function(name: string?): Symbol
		local self = newproxy(true) :: any

		local wrappedName = "Symbol()"
		if name then
			wrappedName = ("Symbol(%s)"):format(name)
		end

		getmetatable(self).__tostring = function()
			return wrappedName
		end

		return (self :: any) :: Symbol
	end,
}