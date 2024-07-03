local types = require('../types')
local isArray = require("isArray")

type Array<T> = types.Array<T>
type PredicateFunction<T> = (value: T, index: number, array: Array<T>) -> boolean

return function<T, S>(source: Array<T> | T, ...: Array<S> | S): Array<T> & Array<S>
    local array
    local elementCount = 0

    if isArray(source) then
        array = table.clone(source :: Array<T>)
        elementCount = #(source :: Array<T>)
    else
        elementCount += 1
        array = { source :: T }
    end

    for i = 1, select('#', ...) do
        local concatWith = select(i, ...)
        local concatWithType = typeof(concatWith)
        if concatWith ~= nil then
            if concatWithType == "table" then
                for k = 1, #concatWith do
                    elementCount += 1
                    array[elementCount] = concatWith[k]
                end
            else
                elementCount += 1
                array[elementCount] = concatWith

            end
        end
    end

    return (array :: any) :: Array<T> & Array<S>
end
