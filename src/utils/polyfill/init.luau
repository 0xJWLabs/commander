local Array = require("array")
local Boolean = require("boolean")
local Console = require("console")
local Math = require("math")
local Map = require("map")
local Number = require("number")
local Object = require("object")
local Set = require("set")
local String = require("string")
local Symbol = require("symbol")
local Timers = require("timers")
local WeakMap = require("weakMap")
local types = require("types")

local AssertionError = require("assertionError")
local Error = require("error")
local PromiseModule = require("promise")
local extends = require("extends")
local instanceof = require("instanceof")
local inspect = require("inspect")

export type Array<T> = types.Array<T>
export type AssertionError = AssertionError.AssertionError
export type Error = Error.Error
export type Map<T, V> = types.Map<T, V>
export type Object = types.Object

export type PromiseLike<T> = PromiseModule.PromiseLike<T>
export type Promise<T> = PromiseModule.Promise<T>

export type Set<T> = types.Set<T>
export type Symbol = Symbol.Symbol
export type Timeout = Timers.Timeout
export type Interval = Timers.Interval
export type WeakMap<T, V> = types.WeakMap<T, V>

return {
	Array = Array,
	AssertionError = AssertionError,
	Boolean = Boolean,
	console = Console,
	Error = Error,
	extends = extends,
	instanceof = instanceof,
	Math = Math,
	Number = Number,
	Object = Object,
	Map = Map.Map,
	coerceToMap = Map.coerceToMap,
	coerceToTable = Map.coerceToTable,
	Set = Set,
	WeakMap = WeakMap,
	String = String,
	Symbol = Symbol,
	setTimeout = Timers.setTimeout,
	clearTimeout = Timers.clearTimeout,
	setInterval = Timers.setInterval,
	clearInterval = Timers.clearInterval,
	util = {
		inspect = inspect,
	},
}