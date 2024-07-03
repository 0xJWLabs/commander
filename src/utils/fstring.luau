local fstring = {}

function fstring.split(input: string, pattern: string?)
    local pattern = pattern or "%s+"
    local parts = {}
    for part in input:gmatch(pattern) do
        table.insert(parts, part)
    end
    return parts
end

function fstring.slice(str: string, startIndexStr: string | number, lastIndexStr: (string | number)?): string
	local strLen, invalidBytePosition = utf8.len(str)
	assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))
	local startIndex = tonumber(startIndexStr)
	assert(typeof(startIndex) == "number", "startIndexStr should be a number")

	if startIndex + strLen < 0 then
		-- then |start index| is greater than string length
		startIndex = 1
	end

	if startIndex > strLen then
		return ""
	end

	-- if no last index length set, go to str length + 1
	local lastIndex = strLen + 1
	if lastIndexStr ~= nil then
		-- ROBLOX FIXME: add parseInt to encapsulate this logic and use it here
		local NaN = 0 / 0
		lastIndex = tonumber(lastIndexStr) or NaN -- this works because 0 is truthy in Lua
	end
	assert(typeof(lastIndex) == "number", "lastIndexStr should convert to number")

	if lastIndex > strLen then
		lastIndex = strLen + 1
	end

	local startIndexByte = utf8.offset(str, startIndex) :: number
	-- get char length of charset retunred at offset
	local lastIndexByte = utf8.offset(str, lastIndex) :: number - 1

	return string.sub(str, startIndexByte, lastIndexByte)
end

-- excluding the `+` and `*` character, since findOr tests and graphql use them explicitly
local luaPatternCharacters = "([" .. ("$%^()-[].?"):gsub("(.)", "%%%1") .. "])"

function fstring.includes(str: string, substring: string, position: (string | number)?): boolean
	local strLen, invalidBytePosition = utf8.len(str)
	assert(strLen ~= nil, ("string `%s` has an invalid byte at position %s"):format(str, tostring(invalidBytePosition)))
	if strLen == 0 then
		return false
	end

	if #substring == 0 then
		return true
	end

	local startIndex = 1
	if position ~= nil then
		startIndex = tonumber(position) or 1
		if startIndex > strLen then
			return false
		end
	end

	if startIndex < 1 then
		startIndex = 1
	end

	local init = utf8.offset(str, startIndex)
	local value = substring:gsub(luaPatternCharacters, "%%%1")
	local iStart, _ = string.find(str, value, init)
	return iStart ~= nil
end

return fstring