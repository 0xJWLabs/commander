export type Array<T> = { T }
export type Table<T, V> = { [T]: V }
export type Tuple<T, V> = Array<T | V>
export type Object = { [string]: any }
export type Function = (...any) -> ...any

export type mapCallbackFn<K, V> = (element: V, key: K, map: Map<K, V>) -> ()
export type mapCallbackFnWithThisArg<K, V> = (
    thisArg: Object,
    value: V,
    key: K,
    map: Map<K, V>
) -> ()

export type Symbol = typeof(newproxy(true)) & { [string]: any }

export type MapImpl<K, V> = {
    __index: Map<K, V>,
    __iter: (self: Map<K, V>) -> (<K, V>({ [K]: V }, K?) -> (K, V), V),
     __newindex: (self: Map<K, V>, key: K, value: V) -> (),
}

export type MapStatics = {
    new: <K, V>(iterable: Array<Array<any>> | Map<K, V>) -> Map<K, V>
}

export type Map<K, V> = typeof(setmetatable(
    {} :: {
        size: number,
        -- method definitions
        set: (self: Map<K, V>, K, V) -> Map<K, V>,
        get: (self: Map<K, V>, K) -> V | nil,
        clear: (self: Map<K, V>) -> (),
        delete: (self: Map<K, V>, K) -> boolean,
        forEach: (
            self: Map<K, V>,
            callback: mapCallbackFn<K, V> | mapCallbackFnWithThisArg<K, V>,
            thisArg: Object?
        ) -> (),
        [K]: V,
        has: (self: Map<K, V>, K) -> boolean,
        keys: (self: Map<K, V>) -> Array<K>,
        values: (self: Map<K, V>) -> Array<V>,
        entries: (self: Map<K, V>) -> Array<Tuple<K, V>>,
        ipairs: (self: Map<K, V>) -> any,
        _map: { [K]: V },
        _array: { [number]: K },
        __index: (self: Map<K, V>, key: K) -> V,
        __iter: (self: Map<K, V>) -> (<K, V>({ [K]: V }, K?) -> (K?, V), V),
        __newindex: (self: Map<K, V>, key: K, value: V) -> (),
    },
    {} :: MapImpl<K, V>
))

export type setCallbackFn<T> = (value: T, key: T, set: Set<T>) -> ()
export type setCallbackFnWithThisArg<T> = (thisArg: Object, value: T, key: T, set: Set<T>) -> ()

export type SetImpl<T> = {
    __index: Set<T>,
	__iter: (self: Set<T>) -> (<K, V>({ [K]: V }, K?) -> (K, V), T),
}

export type Set<T> = typeof(setmetatable(
	{} :: {
		size: number,
		-- method definitions
		add: (self: Set<T>, T) -> Set<T>,
		clear: (self: Set<T>) -> (),
		delete: (self: Set<T>, T) -> boolean,
		forEach: (self: Set<T>, callback: setCallbackFn<T> | setCallbackFnWithThisArg<T>, thisArg: Object?) -> (),
		has: (self: Set<T>, T) -> boolean,
		ipairs: (self: Set<T>) -> any,
	},
	{} :: SetImpl<T>
))

export type WeakMap<K, V> = {
	-- method definitions
	get: (self: WeakMap<K, V>, K) -> V,
	set: (self: WeakMap<K, V>, K, V) -> WeakMap<K, V>,
	has: (self: WeakMap<K, V>, K) -> boolean,
}

return {}
