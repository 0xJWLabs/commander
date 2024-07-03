local function endsWith(value: string, substring: string, optionalLength: number?): boolean
	local substringLength = string.len(substring) 
	if substringLength == 0 then
		return true
	end
	local valueLength = string.len(value)
	local length = optionalLength or valueLength
	if length > valueLength then
		length = valueLength
	end
	if length < 1 then
		return false
	end
	local position = length - substringLength + 1
    return string.find(value, substring, position, true) == position
end

return endsWith