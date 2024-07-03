--!nocheck

local function wrap(f, ...)
    local args = { ... }

    return function(...)
        local __args = { ... }
        for i, value in ipairs(args) do
            table.insert(__args, i, value)
        end

        return f(unpack(__args))
    end
end

local function getNextCase(s, cases)
    for i = s, #cases do
		if typeof(cases[i]) == "table" and cases[i].case then
			return cases[i].case
		end
	end
end

local function run(case, cases)
    local breakIt = false
    local default
    local result

    local function stop()
        breakIt = true
    end

    for i, it in ipairs(cases) do
        local isFunc = typeof(it) == "function"
        if breakIt then 
            return result
        elseif isFunc == false and it.sentence_type == "default" then
            default = it.case
            continue
        end

        it = isFunc and it() or it
		if it.condition ~= case then
			continue
		end

		it.case = it.case or getNextCase(i, cases)
		result = it.case(stop)
        if result ~= nil then
            return result
        end
    end

    if default then
        return default()
    end

    return result
end

local function return_it(sentence_type, condition, case)
    local case_type = typeof(case) == "table"
    
    case = case_type and case[1] or case
    assert(case_type ~= "function", "You must provide a function")

    return {
        sentence_type = sentence_type,
        condition = condition,
        case = case
    }
end

local function switch(value)
    return wrap(run, value)
end

local function default(case)
    return return_it("default", 0, case)
end

local function case(condition)
    assert(condition ~= nil, "You must provide a condition")
    return wrap(return_it, "case", condition)
end

return {
    switch = switch,
    case = case,
    default = default,
}