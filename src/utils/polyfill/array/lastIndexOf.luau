local types = require('../types')

type Array<T> = types.Array<T>
type PredicateFunction<T> = (value: T, index: number, array: Array<T>) -> boolean

return function<T>(array: Array<T>, searchElement: T, fromIndex: number?): number
    local actualFromIndex = fromIndex or 1

    local index

    for i = actualFromIndex, #array do
        if array[i] == searchElement then
            index = i
        end
    end
    return index or -1
end