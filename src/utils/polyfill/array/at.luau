local types = require("../types")
type Array<T> = types.Array<T> 

local function at<T>(t: Array<T>, index: number): T
    if index > #t then
        index = #t
    elseif index == -1 then
        index = #t
    end

    return t[index]
end

return at