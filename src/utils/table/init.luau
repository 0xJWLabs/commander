local Chalk = require("../chalk")

local BaseTable = require("base")

local Table = {}

export type ReprOptions = {
    spaces: number?,
    tabs: boolean?,
    pretty: boolean?,
    semicolons: boolean?,
    sortKeys: boolean?,
    console: boolean?
}

local DEFAULT_SETTINGS = {
	pretty = true,
	tabs = false,
	semicolons = false,
	spaces = 4,
	sortKeys = true,
    console = false,
}

local keywords = {
	["and"] = true,
	["break"] = true,
	["do"] = true,
	["else"] = true,
	["elseif"] = true,
	["end"] = true,
	["false"] = true,
	["for"] = true,
	["function"] = true,
	["if"] = true,
	["in"] = true,
	["local"] = true,
	["nil"] = true,
	["not"] = true,
	["or"] = true,
	["repeat"] = true,
	["return"] = true,
	["then"] = true,
	["true"] = true,
	["until"] = true,
	["while"] = true,
}

local function isLuaIdentifier<T>(str: T)
	if type(str) ~= "string" then
		return false
	end
	-- must be nonempty
	if str:len() == 0 then
		return false
	end
	-- can only contain a-z, A-Z, 0-9 and underscore
	if str:find("[^%d%a_]") then
		return false
	end
	-- cannot begin with digit
	if tonumber(str:sub(1, 1)) then
		return false
	end
	-- cannot be keyword
	if keywords[str] then
		return false
	end
	return true
end

local Colors = {
    boolean = Chalk.hex('#f9e2af'),
    number = Chalk.hex('#74c7ec'),
    ['nil'] = Chalk.hex('#f9e2af'),
}

local INDENT
local shown
local depth = 0
function Table.repr<T>(value: T, reprOptions: ReprOptions?): string
    local reprSettings: ReprOptions = reprOptions or {}
    reprSettings = BaseTable.Reconcile(reprSettings, DEFAULT_SETTINGS)
	INDENT = (" "):rep(reprSettings.spaces :: number)
	if reprSettings.tabs then
		INDENT = "\t"
	end

	local v = value --args[1]
	local tabs = INDENT:rep(depth)

	if depth == 0 then
		shown = {}
	end

	if typeof(v) == "string" then
		return ("%q"):format(v)
	elseif typeof(v) == "number" then
		if v == math.huge then
			return "math.huge"
		end
		if v == -math.huge then
			return "-math.huge"
		end
		return Colors.number(tostring(v))
	elseif typeof(v) == "boolean" then
        return Colors.boolean(tostring(v))
	elseif typeof(v) == "nil" then
		return Colors['nil']('nil')
	elseif typeof(v) == "table" then
		if shown[v] then
			return "{CYCLIC}"
		end
		shown[v] = true
		local str = "{" .. (reprSettings.pretty and ("\n" .. INDENT .. tabs) or "")
		local isArray = true
		for k, v in v do
			if type(k) ~= "number" then
				isArray = false
				break
			end
		end
		if isArray then
			for i = 1, #v do
				if i ~= 1 then
					str = str
						.. (reprSettings.semicolons and ";" or ",")
						.. (reprSettings.pretty and ("\n" .. INDENT .. tabs) or " ")
				end
				depth = depth + 1
				str = str .. Table.repr(v[i])
				depth = depth - 1
			end
		else
			local keyOrder = {}
			local keyValueStrings = {}
			for k, v in v do
				depth = depth + 1
				local kStr = isLuaIdentifier(k) and ("[\"" .. k .. "\"]") or ("[" .. Table.repr(k) .. "]")
				local vStr = Table.repr(v)
				table.insert(keyOrder, kStr)
				keyValueStrings[kStr] = vStr
				depth = depth - 1
			end
			if reprSettings.sortKeys then
				table.sort(keyOrder)
			end
			local first = true
			for _, kStr in keyOrder do
				if not first then
					str = str
						.. (reprSettings.semicolons and ";" or ",")
						.. (reprSettings.pretty and ("\n" .. INDENT .. tabs) or " ")
				end
				str = str .. ("%s = %s"):format(kStr, keyValueStrings[kStr])
				first = false
			end
		end
		shown[v] = false
		if reprSettings.pretty then
			str = str .. "\n" .. tabs
		end
		str = str .. "}"
		return str
	else
		return "<" .. type(v) .. ">"
	end
end

setmetatable(Table, {
    __index = BaseTable
})

return Table
