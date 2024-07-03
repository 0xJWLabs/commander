local function replace(str: string, pattern: string, replacement: string): string
    local replacementstring = string.gsub(str, pattern, replacement)
    return replacementstring
end

return replace
