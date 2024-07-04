local Table = {}

export type Table<T> = { T }
export type Object<K, V> = { [K]: V }
type callbackFn<T> = (value: T, index: number, array: Table<T>) -> boolean
type reduceFn<T, U> = (previousValue: U, currentValue: T, currentIndex: number, array: Table<T>) -> U
type predicateFunction<K, V> = (value: V, index: K, array: Object<K, V>) -> boolean
type mapCallbackFn<T, U> = (value: T, index: number, Table<T>) -> U

function Table.isArray<T>(t: T)
    if typeof(t) ~= 'table' then
        return false
    end

    for key in t :: any do
        if typeof(key) ~= 'number' then
            return false
        end
    end

    return true
end

function Table.find<K, V>(t: Object<K, V>, predicate: predicateFunction<K, V>, start: number?): V?
    if typeof(t) ~= 'table' then
		error(string.format("Table.spread called on non-table %s", typeof(t)))
	end	
    if start then
        if not Table.isArray(t) then
            error(string.format("Table.spread called on non-array %s", 'object')) 
        end
        local length = #t
        for i = start, length do
            local value = t[i :: any]
            if predicate(value, i :: any, t) then
                return value
            end
        end
    else
        for index, value in t do
            if predicate(value, index, t) then
                return value
            end
        end
    end

    return nil
end

function Table.spread<T>(array: Table<T>, i: number?, j: number?): ...T
    if not Table.isArray(array) then
		error(string.format("Table.spread called on non-array %s", typeof(array)))
	end	
    local startIndex = i or 1
    local endIndex = j or #array
    if startIndex > endIndex then
        return  -- Return nothing if start index exceeds end index
    end

    local results = {}
    local count = 0
    for i = startIndex, endIndex do
        count += 1
        results[count] = array[i]
    end

    local function spread_helper(t, i)
        if i > count then
            return
        else
            return t[i], spread_helper(t, i + 1)
        end
    end

    return spread_helper(results, 1)	
end

function Table.reduce<T, U>(array: Table<T>, callback: reduceFn<T, U>, initialValue: U?): U
    if not Table.isArray(array) then
		error(string.format("Table.reduce called on non-table %s", typeof(array)))
	end	 
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

	local length = #array

	local value: T | U
	local initial = 1

	if initialValue ~= nil then
		value = initialValue
	else
		initial = 2
		if length == 0 then
			error("reduce of empty array with no initial value")
		end
		value = array[1]
	end

	for i = initial, length do
		value = callback(value :: U, array[i], i, array)
	end

	return value :: U
end

function Table.filter<T, U>(array: Table<T>, callback: callbackFn<T>): Table<T>
    if typeof(array) ~= "table" then
        error(string.format("Array.filter called on %s", typeof(array)))
    end

    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

    local result: Table<T> = {}

    for i, element in array do
        if callback(element, i , array) then
            table.insert(result, element)
        end
    end

    return result
end

function Table.map<T, U, V>(array: Table<T>, callback: mapCallbackFn<T, U>): Table<U>
    if not Table.isArray(array) then
        error(string.format("Array.map called on non-array %s", typeof(array)))
    end
    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

	local new = {}

    for i, value in array do
        local mappedValue: U = callback(value, i, array)

        if mappedValue ~= nil then
            table.insert(new, mappedValue)
        end
    end

    return new
end

function Table.copy<K, V>(t: Object<K, V>, deep: boolean?): Object<K, V>
    if not deep then
		return table.clone(t)
	end
	local clone = table.clone(t)
	for index, value in clone do
		if typeof(value) == "table" then
			clone[index] = Table.copy(value, deep) :: any 
		end
	end
	return clone 
end

function Table.reconcile<S, T>(src: S, template: T): S & T
    assert(type(src) == "table", "First argument must be a table")
	assert(type(template) == "table", "Second argument must be a table")

    local tbl = table.clone(src)

    for key, value in template :: Object<any, any> do
        if tbl[key] == nil then
			if typeof(value) == "table" then
				tbl[key] = Table.copy(value :: any, true)
			else
				tbl[key] = value
			end
		elseif typeof((template :: {})[key]) == "table" then
			if typeof(value) == "table" then
				tbl[key] = Table.reconcile(value :: any, (template :: {})[key])
			else
				tbl[key] = Table.copy((template :: {})[key], true)
			end
		end
    end

    return (tbl :: any) :: S & T
end

return Table