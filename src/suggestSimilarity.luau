local function compareTwoStrings(first: string, second: string)
    first = first:gsub('%s+', '')
    second = second:gsub('%s+', '')

    if first == second then
        return 1
    end -- identical or empty
    if #first < 2 or #second < 2 then
        return 0
    end -- if either is a 0-letter or 1-letter string

    local firstBigrams = {}
    for i = 1, #first - 1 do
        local bigram = first:sub(i, i + 1)
        firstBigrams[bigram] = (firstBigrams[bigram] or 0) + 1
    end

    local intersectionSize = 0
    for i = 1, #second - 1 do
        local bigram = second:sub(i, i + 1)
        if firstBigrams[bigram] and firstBigrams[bigram] > 0 then
            firstBigrams[bigram] = firstBigrams[bigram] - 1
            intersectionSize = intersectionSize + 1
        end
    end

    return (2.0 * intersectionSize) / (#first + #second - 2)
end

local function areArgsValid(mainString, targetStrings)
    if type(mainString) ~= 'string' then
        return false
    end
    if type(targetStrings) ~= 'table' then
        return false
    end
    if #targetStrings == 0 then
        return false
    end
    for _, s in ipairs(targetStrings) do
        if type(s) ~= 'string' then
            return false
        end
    end
    return true
end

local function findBestMatch(mainString: string, targetStrings: { string })
    if not areArgsValid(mainString, targetStrings) then
        error('Bad arguments: First argument should be a string, second should be an array of strings')
    end

    local ratings = {}
    local bestMatchIndex = 1

    for i, currentTargetString in ipairs(targetStrings) do
        local currentRating = compareTwoStrings(mainString, currentTargetString)
        table.insert(ratings, { target = currentTargetString, rating = currentRating })
        if currentRating > ratings[bestMatchIndex].rating then
            bestMatchIndex = i
        end
    end

    local bestMatch = ratings[bestMatchIndex]

    return { ratings = ratings, bestMatch = bestMatch, bestMatchIndex = bestMatchIndex }
end

local function suggestSimilar(word: string, candidates: { string })
    if not candidates or #candidates == 0 then
        return ''
    end

    local minDistance = 0.5
    local bestMatches = findBestMatch(word, candidates)
    local ratings = bestMatches.ratings

    local results = {}

    for _, rating in ratings do
        if rating.rating >= minDistance then
            table.insert(results, rating.target)
        end
    end

    if #results > 1 then
        return '\n(Did you mean one of ' .. table.concat(results, ', ') .. '?)'
    end
    if #results == 1 then
        return '\n(Did you mean ' .. results[1] .. '?)'
    end

    return ''
end

return {
    compareTwoStrings = compareTwoStrings,
    findBestMatch = findBestMatch,
    suggestSimilar = suggestSimilar,
}
