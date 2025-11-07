local fuzzy = require("extlibs.fts_fuzzy_match")

local search = {}

local current_pattern = nil

---comment
---@param pattern string
function search.start(pattern)
    current_pattern = pattern
end

function search.match(str)
    if not current_pattern then
        error("no current pattern")
    end
    return fuzzy.fuzzy_match_simple(current_pattern, str)
end

function search.match_with_label() end

function search.finish()
    current_pattern = nil
end

return search
