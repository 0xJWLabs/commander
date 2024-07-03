local types = require("../types")

type Array<T> = types.Array<T>

return function<T>(value: Array<T>): boolean
    return next(value) == nil
end