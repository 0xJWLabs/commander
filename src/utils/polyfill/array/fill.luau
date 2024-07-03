local types = require('../types')

type Array<T> = types.Array<T>
type callbackFn<T> = (value: T, index: number, array: Array<T>) -> boolean
type callbackFnWithArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> boolean

return function<T, U>(array: Array<T>, value: T, start: number?, End: number?): Array<T>
    if typeof(array) ~= "table" then
        error(string.format("Array.filter called on %s", typeof(array)))
    end

    local new = table.clone(array)

    local start = start or 1
    local End = End or #new

    for i = start, End do
        new[i] = value
    end

    return new
end
