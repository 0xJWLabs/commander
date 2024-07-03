local types = require('../types')

type Array<T> = types.Array<T>
type PredicateFunction<T> = (value: T, index: number, array: Array<T>) -> boolean

return function<T>(array: Array<T>, predicate: PredicateFunction<T>, start: number?): number
    if start == nil or start == 1 then
        for index, value in array do
            if predicate(value, index, array) then
                return index
            end
        end
    else
        local length = #array
        for i = start, length do
            local value = array[i]
            if predicate(value, i, array) then
                return i

            end
        end
    end

    return -1
end
