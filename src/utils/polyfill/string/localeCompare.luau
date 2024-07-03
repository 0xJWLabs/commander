local function normalize(str: string): string
    -- Basic normalization: remove diacritics
    -- Replace this with a proper Unicode normalization function as per your needs
	local normalized = {}
    
    -- Replace accents and normalize case
    local function replaceAccents(c)
        local replacement = {
            ["À"] = "A", ["Á"] = "A", ["Â"] = "A", ["Ã"] = "A", ["Ä"] = "A", ["Å"] = "A",
            ["à"] = "a", ["á"] = "a", ["â"] = "a", ["ã"] = "a", ["ä"] = "a", ["å"] = "a",
            ["È"] = "E", ["É"] = "E", ["Ê"] = "E", ["Ë"] = "E",
            ["è"] = "e", ["é"] = "e", ["ê"] = "e", ["ë"] = "e",
            ["Ì"] = "I", ["Í"] = "I", ["Î"] = "I", ["Ï"] = "I",
            ["ì"] = "i", ["í"] = "i", ["î"] = "i", ["ï"] = "i",
            ["Ò"] = "O", ["Ó"] = "O", ["Ô"] = "O", ["Õ"] = "O", ["Ö"] = "O",
            ["ò"] = "o", ["ó"] = "o", ["ô"] = "o", ["õ"] = "o", ["ö"] = "o",
            ["Ù"] = "U", ["Ú"] = "U", ["Û"] = "U", ["Ü"] = "U",
            ["ù"] = "u", ["ú"] = "u", ["û"] = "u", ["ü"] = "u",
            ["Ý"] = "Y", ["ý"] = "y", ["ÿ"] = "y",
            ["Ç"] = "C", ["ç"] = "c",
            ["Ñ"] = "N", ["ñ"] = "n"
        }
        return replacement[c] or c
    end
    
    for _, codepoint in utf8.codes(str) do
        local code = codepoint
        local normalizedChar = replaceAccents(utf8.char(code))
        table.insert(normalized, normalizedChar)
        -- local normalizedChar = utf8.char(replaceAccents(utf8.char(code)))
    end

    return table.concat(normalized) 

    -- return string.gsub(str, "[%z\1-\127\194-\244][\128-\191]*", "")
end

local function localeCompare(str1: string, str2: string): number
    -- Normalize and lowercase strings for case and diacritic insensitivity
    local normalized1 = normalize(str1):lower()
    local normalized2 = normalize(str2):lower()

    
    -- Compare normalized strings
	-- Compare normalized strings lexicographically
    if normalized1 < normalized2 then
        return -1
    elseif normalized1 > normalized2 then
        return 1
    else
        return 0
    end
end

return localeCompare