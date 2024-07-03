local Number = {}

Number.MAX_SAFE_INTEGER = 9007199254740991
Number.MIN_SAFE_INTEGER = -9007199254740991
Number.NaN = 0 / 0

function Number.isFinite(value)
    return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Number.isInteger(value)
    return type(value) == "number" and value ~= math.huge and value == math.floor(value)
end

function Number.isNaN(value)
    return type(value) == "number" and value ~= value
end

function Number.isSafeInteger(value)
    return Number.isInteger(value) and math.abs(value) <= Number.MAX_SAFE_INTEGER
end

function Number.toExponential(value: string | number, fractionDigits: number?): string?
    local num = value
	if typeof(value) == "string" then
		-- ROBLOX FIXME: add parseInt to encapsulate this logic and use it here
		local NaN = 0 / 0
		num = tonumber(value) or NaN -- works because 0 is truthy in Lua
	end
	-- returns nil for invalid input instead of nan to be more lua-native
	if typeof(num) ~= "number" then
		return "nan"
	end

	if fractionDigits ~= nil then
		if typeof(fractionDigits) ~= "number" then
			error("TypeError: fractionDigits must be a number between 0 and 100")
		end
		if fractionDigits < 0 or fractionDigits > 100 then
			error("RangeError: fractionDigits must be between 0 and 100")
		end
	end

	local formatString
	if fractionDigits == nil then
		formatString = "%e"
	else
		formatString = "%." .. tostring(fractionDigits) .. "e"
	end

	local retval = string.format(formatString, num):gsub("%+0", "+"):gsub("%-0", "-"):gsub("0*e", "e")

	return retval
end

return Number