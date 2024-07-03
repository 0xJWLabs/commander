local types = require('../types')

type Array<T> = types.Array<T>
type PredicateFunction<T> = (value: T, index: number, array: Array<T>) -> boolean

return function<T>(array: Array<T>, predicate: PredicateFunction<T>): boolean
    for index, value in array do
        if not predicate(value, index, array) then
            return false
        end
    end

    return true
end
