local arrayForEach = require('../array/forEach')
local arrayMap = require('../array/map')
local instanceof = require('../instanceof')
local isArray = require('../array/isArray')
local types = require('../types')

type Object = types.Object
type Array<T> = types.Array<T>
type Table<T, V> = types.Table<T, V>
type Tuple<T, V> = types.Tuple<T, V>
type mapCallbackFn<K, V> = types.mapCallbackFn<K, V>
type mapCallbackFnWithThisArg<K, V> = types.mapCallbackFnWithThisArg<K, V>
export type Map<K, V> = types.Map<K, V>
type MapImpl<K, V> = types.MapImpl<K, V>
type MapStatics = types.MapStatics

local Map = {} :: Map<any, any> & MapStatics

function Map.new<K, V>(iterable: (Array<Array<any>> | Map<K, V>)?): Map<K, V>
    local array
    local map
    if iterable == nil then
        array = {}
        map = {}
    elseif isArray(iterable) then
        if
            #(iterable :: Array<Array<any>>) > 0
            and typeof((iterable :: Array<Array<any>>)[1]) ~= 'table'
        then
            error(
                'Value `'
                    .. typeof((iterable :: Array<Array<any>>)[1])
                    .. '` is not an entry object.\n '
                    .. 'Cannot create Map from {K, V} form, it must be { {K, V}... }'
            )
        end
        array = table.create(#(iterable :: Array<Array<any>>))
        map = {}
        for _, entry in iterable :: Array<Array<any>> do
            local key = entry[1]
            if key == nil then
                error("cannot create Map from a table that isn't an array.")
            end
            local val = entry[2]
            -- only add to array if new
            if map[key] == nil then
                table.insert(array, key)
            end
            -- always assign
            map[key] = val
        end
    elseif instanceof(iterable, Map) then
        array = table.clone((iterable :: Map<K, V>)._array)
        map = table.clone((iterable :: Map<K, V>)._map)
    else
        error(
            ('`%s` `%s` is not iterable, cannot make Map using it'):format(
                typeof(iterable),
                tostring(iterable)
            )
        )
    end

    return (
        setmetatable({
            size = #array,
            _map = map,
            _array = array,
        }, {
            __index = Map,
            __iter = function(self: Map<K, V>)
                return next, self:entries()
            end
        }) :: any
    ) :: Map<K, V>
end

function Map.set<K, V>(self: Map<K, V>, key: K, value: V): Map<K, V>
    -- preserve initial insertion order
    if self._map[key] == nil then
        -- Luau FIXME: analyze should know self is Map<K, V> which includes size as a number
        self.size = self.size :: number + 1
        table.insert(self._array, key)
    end
    -- always update value
    self._map[key] = value
    return self
end


function Map.get<K, V>(self: Map<K, V>, key: K): V
    return self._map[key]
end

function Map.clear<K, V>(self: Map<K, V>)
    local table_: any = table
    self.size = 0
    table_.clear(self._map)
    table_.clear(self._array)
end

function Map.delete<K, V>(self: Map<K, V>, key: K): boolean
    if self._map[key] == nil then
        return false
    end
    -- Luau FIXME: analyze should know self is Map<K, V> which includes size as a number
    self.size = self.size :: number - 1
    self._map[key] = nil
    local index = table.find(self._array, key)
    if index then
        table.remove(self._array, index)
    end
    return true
end

function Map.forEach<K, V>(
    self: Map<K, V>,
    callback: mapCallbackFn<any, any> | mapCallbackFnWithThisArg<any, any>,
    thisArg: Object?
): ()
    if typeof(callback) ~= 'function' then
        error('callback is not a function')
    end
    -- note: we can't turn this into a simple for-in loop, because the callbacks can modify the table and React, GQL, and Jest rely on JS behavior in that scenario
    arrayForEach(self._array, function(key)
        local value = self._map[key]

        if thisArg ~= nil then
            (callback :: mapCallbackFnWithThisArg<any, any>)(thisArg, value, key, self)
        else
            (callback :: mapCallbackFn<any, any>)(value, key, self)
        end
    end)
end

function Map.has<K, V>(self: Map<K, V>, key: K): boolean
    return self._map[key] ~= nil
end

function Map.keys<K, V>(self: Map<K, V>)
    return self._array
end

function Map.values<K, V>(self: Map<K, V>): Array<V>
    return arrayMap(self._array, function(key)
        return self._map[key]
    end)
end

function Map.entries<K, V>(self: Map<K, V>): Array<Tuple<K, V>>
    return arrayMap(self._array, function(key): { K | V }
        return { key, self._map[key] }
    end)
end

function Map.ipairs<K, V>(self: Map<K, V>)
    warn(
        debug.traceback(
            '`for _,_ in myMap:ipairs() do` is deprecated and will be removed in a future release, please use `for _,_ in myMap do` instead\n',
            2
        )
    )
    return ipairs(self:entries())
end

function Map.__iter<K, V>(self: Map<K, V>)
    return next, self:entries()
end

function Map.__index<K, V>(self: Map<K, V>, key)
    local mapProp = rawget(Map, key)
    if mapProp ~= nil then
        return mapProp
    end
    assert(
        -- FIXME Luau: shouldn't need this cast, the self param is annotated already
        rawget(self :: any, '_map'),
        'Map has been corrupted, and is missing private state! Did you accidentally call table.clear() instead of map:clear()?'
    )

    return Map.get(self, key)
end

function Map.__newindex<K, V>(self: Map<K, V>, key, value)
    self:set(key, value)
end

return Map