local types = require('../types')

type Array<T> = types.Array<T>
type callbackFn<T> = (value: T, index: number, array: Array<T>) -> boolean
type callbackFnWithArg<T, U> = (thisArg: U, element: T, index: number, array: Array<T>) -> boolean

return function<T, U>(array: Array<T>, callback: callbackFn<T> | callbackFnWithArg<T, U>, arg: U?): Array<T>
    if typeof(array) ~= "table" then
        error(string.format("Array.filter called on %s", typeof(array)))
    end

    if typeof(callback) ~= "function" then
        error("callback is not a function")
    end

    local result: Array<T> = {}

    for i, element in array do
        local match: boolean
        if arg == nil then
           if (callback :: callbackFn<T>)(element, i, array) then
                table.insert(result, element)         
           end
        else
            if (callback :: callbackFnWithArg<T, U>)(arg, element, i, array) then
                table.insert(result, element)         
           end
        end
    end

    return result
end
