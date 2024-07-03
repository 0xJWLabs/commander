local types = require('../types')

type Array<T> = types.Array<T>
type PredicateFunction<T> = (value: T, index: number, array: Array<T>) -> boolean

return function<T>(array: Array<T>, value: T, start: number?): number
    return table.find(array, value, start) or -1
end