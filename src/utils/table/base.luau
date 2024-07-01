export type Array<T> = { [number]: T }

local BaseTable = {}

function BaseTable.Keys<K, V>(tbl: { [K]: V }): { K }
	local keys: { K } = {}

	for key in tbl do
		table.insert(keys, key)
	end

	return keys
end

function BaseTable.Values<K, V>(tbl: { [K]: V }): { V }
	local values: { V } = {} 
	for _, v in tbl do
		table.insert(values, v)
	end
	return values
end

function BaseTable.ValuesExcept<K, V>(tbl: { [K]: V }, except: { K }): { V }
	local values: { V } = {} 
	for k, v in tbl do
		if not table.find(except, k) then
			values[k :: any] = v
		end
	end
	return values
end

function BaseTable.ForEach<K, V>(tbl: { [K]: V }, callback: (V, K, { [K]: V }) -> ())
	for index, value in tbl do
		callback(value, index, tbl)
	end
end

function BaseTable.Index<T>(tbl: {T}, value: T, start: number?): number
	return table.find(tbl, value, start) or -1
end

function BaseTable.Includes<T>(tbl: { T }, searchElement: T, fromIndex: number?): boolean
	return BaseTable.Index(tbl, searchElement, fromIndex) ~= -1
end

function BaseTable.Find<K, V>(tbl: { [K]: V }, callback: (V, K, { [K]: V }) -> boolean): (V?, K?)
	for k, v in tbl do
		if callback(v, k, tbl) then
			return v, k
		end
	end
	return nil, nil
end

function BaseTable.Except<K, V>(t: { [K]: V }, except: { K | V }): { [K]: V }
	assert(type(t) == "table", "First argument must be a table")
	local newT: { [K]: V } = {} 
	if #t > 0 then
		local n = 0
		for _, v in t do
			if not table.find(except :: any, v) then
				n += 1
				newT[n :: any] = v
			end
		end
	else
		for k, v in t do
			if not except[k :: any] then
				newT[k :: any] = v
			end
		end
	end
	return newT
end

function BaseTable.StringOrNumber<K, V>(tbl: { [K]: V} ): string?
    local hasNumbers = false
    local hasStrings = false

    for _, value in ipairs(tbl :: any) do
        if type(value) == "number" then
            hasNumbers = true
        elseif type(value) == "string" then
            hasStrings = true
        end

        -- If both types of elements are found, we can't classify it as purely one or the other.
        if hasNumbers and hasStrings then
            return
        end
    end

    if hasNumbers then
        return "number array"
    elseif hasStrings then
        return "string array"
	end

	return
end

function BaseTable.IsUnique<K, V>(dict1: { [K]: V }, dict2: {[K]: V })
	for key, value in dict1 do
		if type(value) == "table" then
			if BaseTable.IsUnique(value, dict2[key]) then
				return true
			end
		else
			if value ~= dict2[key] then
				return true
			end
		end
	end

	return false
end

function BaseTable.IsArray<T, K>(tbl: { [T]: K }): boolean
	local count = 0
	for _ in tbl do
		count += 1
	end
	
	return count == #tbl
end

function BaseTable.IsDictionary<T, K>(tbl: { [T]: K }): boolean
	local count = 0
	for _ in tbl do
		count += 1
	end
	
	return count ~= #tbl
end

function BaseTable.Size<T, K>(tbl: { [T]: K }): number
	local count = 0
	for _ in tbl do
		count += 1
	end

	return count
end

function BaseTable.AssignClone<J, K, L, M>(tbl: J, source1: K?, source2: L?, source3: M?, ...): J & K & L & M
	local cloned: J & K & L & M = {} :: any

	for key, value in tbl :: any do
		(cloned :: any)[key] = value
	end

	if source1 and typeof(source1) == "table" then
		for key, value in source1 :: any do
			(cloned :: any)[key] = value
		end
	end

	if source2 and typeof(source2) == "table" then
		for key, value in source2 :: any do
			(cloned :: any)[key] = value
		end
	end

	if source3 and typeof(source3) == "table" then
		for key, value in source3 :: any do
			(cloned :: any)[key] = value
		end
	end

	for index = 1, select("#", ...) do
		local rest = select(index, ...)

		if rest ~= nil and typeof(rest) == "table" then
			for key, value in rest do
				(cloned :: any)[key] = value
			end
		end
	end

	return cloned
end

function BaseTable.Copy<T>(t: T & {}, deep: boolean?): T
	if not deep then
		return (table.clone(t :: any) :: any) :: T
	end
	local clone = table.clone(t)
	for index, value in clone do
		if typeof(value) == "table" then
			clone[index] = BaseTable.Copy(value :: { [any]: any }, deep)
		end
	end
	return (clone :: any) :: T
end

function BaseTable.Reconcile<S, T>(src: S & {}, template: T & {}): T
	assert(type(src) == "table", "First argument must be a table")
	assert(type(template) == "table", "Second argument must be a table")
	local tbl = table.clone(src) 

	for key, value in template :: {} do
		if tbl[key] == nil then
			if typeof(value) == "table" then
				tbl[key] = BaseTable.Copy(value :: any, true)
			else
				tbl[key] = value
			end
		elseif typeof((template :: {})[key]) == "table" then
			if typeof(value) == "table" then
				tbl[key] = BaseTable.Reconcile(value :: any, (template :: {})[key])
			else
				tbl[key] = BaseTable.Copy((template :: {})[key], true)
			end
		end
	end

	return (tbl :: any) :: T
end

function BaseTable.Merge<T, K>(tbl1: { [T]: K }, tbl2: { [T]: K }): T & K
	assert(type(tbl1) == "table", "First argument must be a table")
	assert(type(tbl2) == "table", "Second argument must be a table")
	
	local isBaseTable1Dictionary = BaseTable.IsDictionary(tbl1)
	local isBaseTable2Dictionary = BaseTable.IsDictionary(tbl2)
	
	if isBaseTable1Dictionary and isBaseTable2Dictionary then
		local newBaseTable = table.clone(tbl1)

		for key, value in tbl2 do
			newBaseTable[key] = value
		end

		return (newBaseTable :: any) :: T & K
	end
	
	local result = table.clone(tbl2)
	table.move(tbl2 :: any, 1, #tbl1, #result + 1, result :: any)
	return (result :: any) :: T & K
end

function BaseTable.Assign<T, U, V, W>(target: T, source0: U?, source1: V?, source2: W, ...): T & U & V & W
	local function assign(src: any): ()
		if src ~= nil and typeof(src) == "table" then
			for key, value in pairs(src) do
				if value == nil then
					(target :: any)[key] = nil :: any
				else
					(target :: any)[key] = value :: any
				end
			end
		end
	end

	assign(source0)
	assign(source1)
	assign(source2)

	for index = 1, select("#", ...) do
        local rest = select(index, ...)
        assign(rest)
    end

	return (target :: any) :: T & U & V & W
end

function BaseTable.ToString(obj: { [any]: any }): string
	local function stringify(value)
		if typeof(value) == "string" then
			return '"' .. tostring(value) .. '"'
		else
			return tostring(value)
		end
	end

	local function stringifyBaseTable(obj, indent: number)
		local result = {}
		for key, value in obj do
			local stringifiedKey = (typeof(key) == "string") and ('"' .. tostring(key) .. '"') or tostring(key)
			local stringifiedValue

			if typeof(value) == "table" then
				stringifiedValue = stringifyBaseTable(value, indent + 1)
			else
				stringifiedValue = stringify(value)
			end

			local newline = ("\t"):rep(indent) .. "[" .. stringifiedKey .. "] = " .. stringifiedValue
			table.insert(result, newline)
		end
		return "{\n" .. table.concat(result, ",\n") .. "\n" .. ("\t"):rep(indent - 1) .. "}"
	end

	return stringifyBaseTable(obj, 1)
end

setmetatable(BaseTable, {
    __index = table
})

return BaseTable