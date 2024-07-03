local types = require("../types")

type Array<T> = types.Array<T>
type mapFn<T> = (index: number) -> T?

return function<T>(fn: mapFn<T>, strict: boolean?): Array<T>
    local array = {}

    local i = 1
    while true do
        if strict then
            local success, element = pcall(fn, i)
            if success == false or element == nil then
                break
            else
                i += 1
                table.insert(array, element)
            end
        else
            local element = fn(i)
            if element == nil then
                break
            else
                i += 1
                table.insert(array, element)
            end
        end
    end

    return array
end