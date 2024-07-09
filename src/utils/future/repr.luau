local function copy<K, V>(t: { [K]: V }, deep: boolean?): { [K]: V }
    if not deep then
        return table.clone(t)
    end
    local clone = table.clone(t)
    for index, value in clone do
        if typeof(value) == 'table' then
            clone[index] = copy(value, deep) :: any
        end
    end
    return clone
end

-- Table Function Start
local function reconcile<S, T>(src: S, template: T): S & T
    assert(type(src) == 'table', 'First argument must be a table')
    assert(type(template) == 'table', 'Second argument must be a table')

    local tbl = table.clone(src)

    for key, value in template :: { [any]: any } do
        if tbl[key] == nil then
            if typeof(value) == 'table' then
                tbl[key] = copy(value :: any, true)
            else
                tbl[key] = value
            end
        elseif typeof((template :: {})[key]) == 'table' then
            if typeof(value) == 'table' then
                tbl[key] = reconcile(value :: any, (template :: {})[key])
            else
                tbl[key] = copy((template :: {})[key], true)
            end
        end
    end

    return (tbl :: any) :: S & T
end
-- Table Function End

-- Color Function Start
local function replaceAll(str: string, searchValue: string, replaceValue: string)
    if searchValue == '' then
        return str
    end

    local substringLength = #searchValue
    local lastPos = 1
    local result = ''
    local pos

    while true do
        pos = string.find(str, searchValue, lastPos, true)
        if not pos then
            break
        end
        result ..= string.sub(str, lastPos, pos - 1) .. replaceValue
        lastPos = pos + substringLength
    end

    return lastPos > 1 and result .. string.sub(str, lastPos) or str
end

local function stringEncaseCRLFWithFirstIndex(string_: string, prefix: string, postfix: string, index: number): string
    local endIndex = 1
    local returnValue = ''
    repeat
        local gotCR = string.sub(string_, index - 1, index - 1) == '\r'
        returnValue ..= string.sub(string_, endIndex, if gotCR then index - 2 else index - 1) .. prefix .. (if gotCR
            then '\r\n'
            else '\n') .. postfix
        endIndex = index + 1
        index = string.find(string_, '\n', endIndex) :: number
    until not (index ~= nil)
    returnValue ..= string.sub(string_, endIndex)
    return returnValue
end

local function hexToRgb(value: string): { number }
    local color = string.match(value, '([a-fA-F%d]+)')
    local len = color and #color or 0

    if len == 3 then
        color = string.sub(color :: string, 1, 1)
            .. string.sub(color :: string, 1, 1)
            .. string.sub(color :: string, 2, 2)
            .. string.sub(color :: string, 2, 2)
            .. string.sub(color :: string, 3, 3)
            .. string.sub(color :: string, 3, 3)
    elseif len ~= 6 then
        return { 0, 0, 0 }
    end

    local num = tonumber(color, 16) :: number

    local r = bit32.rshift(bit32.band(num, 0xFF0000), 16)
    local g = bit32.rshift(bit32.band(num, 0x00FF00), 8)
    local b = bit32.band(num, 0x0000FF)

    return { r, g, b }
end

local function colorify(hex: string)
    local rgb = hexToRgb(hex)
    local open = `\x1b[38;2;{rgb[1]};{rgb[2]};{rgb[3]}m`
    local close = `\x1b[39m`

    return function(...: string)
        local strs = {}
        for i = 1, select('#', ...) do
            local value = select(i, ...)
            if typeof(value) == 'table' then
                value = {}
            end
            if value == nil or type(value) == 'string' and #value == 0 then
                return ''
            end

            if string.match(value, `\x1b`) then
                value = replaceAll(value, close, open)
            end

            local lfIndex = string.find(value, '\n')
            if lfIndex ~= nil then
                value = stringEncaseCRLFWithFirstIndex(value, open, close, lfIndex)
            end

            table.insert(strs, `{open}{value}{close}`)
        end
        return `{table.concat(strs, ' ')}`
    end
end
-- Color Function Emd

export type ReprOptions = {
    spaces: number?,
    tabs: boolean?,
    pretty: boolean?,
    semicolons: boolean?,
    sortKeys: boolean?,
    console: boolean?,
    colors: boolean?,
}

local DEFAULT_SETTINGS = {
    pretty = true,
    tabs = false,
    semicolons = false,
    spaces = 4,
    sortKeys = true,
    console = false,
    colors = true,
}

local keywords = {
    ['and'] = true,
    ['break'] = true,
    ['do'] = true,
    ['else'] = true,
    ['elseif'] = true,
    ['end'] = true,
    ['false'] = true,
    ['for'] = true,
    ['function'] = true,
    ['if'] = true,
    ['in'] = true,
    ['local'] = true,
    ['nil'] = true,
    ['not'] = true,
    ['or'] = true,
    ['repeat'] = true,
    ['return'] = true,
    ['then'] = true,
    ['true'] = true,
    ['until'] = true,
    ['while'] = true,
}

local function isLuaIdentifier<T>(str: T)
    if type(str) ~= 'string' then
        return false
    end
    -- must be nonempty
    if str:len() == 0 then
        return false
    end
    -- can only contain a-z, A-Z, 0-9 and underscore
    if str:find('[^%d%a_]') then
        return false
    end
    -- cannot begin with digit
    if tonumber(str:sub(1, 1)) then
        return false
    end
    -- cannot be keyword
    if keywords[str] then
        return false
    end
    return true
end

local Colors = {
    boolean = colorify('#f9e2af'),
    number = colorify('#74c7ec'),
    ['nil'] = colorify('#f9e2af'),
}

local INDENT
local shown
local depth = 0
local function repr<T>(value: T, reprOptions: ReprOptions?): string
    local reprSettings: ReprOptions = reprOptions or {}
    reprSettings = reconcile(reprSettings, DEFAULT_SETTINGS)
    INDENT = (' '):rep(reprSettings.spaces :: number)
    if reprSettings.tabs then
        INDENT = '\t'
    end

    local v = value --args[1]
    local tabs = INDENT:rep(depth)

    if depth == 0 then
        shown = {}
    end

    if typeof(v) == 'string' then
        return ('%s'):format(v)
    elseif typeof(v) == 'number' then
        if v == math.huge then
            return 'math.huge'
        end
        if v == -math.huge then
            return '-math.huge'
        end
        return reprSettings.colors and Colors.number(tostring(v)) or tostring(v)
    elseif typeof(v) == 'boolean' then
        return reprSettings.colors and Colors.boolean(tostring(v)) or tostring(v)
    elseif typeof(v) == 'nil' then
        return reprSettings.colors and Colors['nil']('nil') or 'nil'
    elseif typeof(v) == 'table' then
        if shown[v] then
            return '{CYCLIC}'
        end
        shown[v] = true
        local str = '{' .. (reprSettings.pretty and ('\n' .. INDENT .. tabs) or '')
        local isArray = true
        for k, _ in v do
            if type(k) ~= 'number' then
                isArray = false
                break
            end
        end
        if isArray then
            for i = 1, #v do
                if i ~= 1 then
                    str = str
                        .. (reprSettings.semicolons and ';' or ',')
                        .. (reprSettings.pretty and ('\n' .. INDENT .. tabs) or ' ')
                end
                depth = depth + 1
                str = str .. repr(v[i])
                depth = depth - 1
            end
        else
            local keyOrder = {}
            local keyValueStrings = {}
            for k, v in v do
                depth = depth + 1
                local kStr = isLuaIdentifier(k) and ('' .. k .. '') or ('' .. repr(k) .. '')
                local vStr = repr(v)
                table.insert(keyOrder, kStr)
                keyValueStrings[kStr] = vStr
                depth = depth - 1
            end
            if reprSettings.sortKeys then
                table.sort(keyOrder)
            end
            local first = true
            for _, kStr in keyOrder do
                if not first then
                    str = str
                        .. (reprSettings.semicolons and ';' or ',')
                        .. (reprSettings.pretty and ('\n' .. INDENT .. tabs) or ' ')
                end
                str = str .. ('%s = %s'):format(kStr, keyValueStrings[kStr])
                first = false
            end
        end
        shown[v] = false
        if reprSettings.pretty then
            str = str .. '\n' .. tabs
        end
        str = str .. '}'
        return str
    else
        return '<' .. type(v) .. '>'
    end
end

return repr
