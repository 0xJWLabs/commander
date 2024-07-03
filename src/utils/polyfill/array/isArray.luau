return function<T>(value: T): boolean
	if typeof(value) ~= "table" then
		return false
	end
	if next(value) == nil then
		-- an empty table is an empty array
		return true
	end

	local length = #value

	if length == 0 then
		return false
	end

    local expected = 0
    for key in value :: { [any]: any } do
        expected += 1
        if typeof(key) ~= "number" or key ~= expected then
            return false
        end
    end

	return length == expected 
end