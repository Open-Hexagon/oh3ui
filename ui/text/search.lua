local fuzzy = require("extlibs.fts_fuzzy_match")
local buffer = require("string.buffer")
local ansi = require("ui.text.ansi")
local memoize = require("extlibs.memoize")

---highlights a string using matched indices
---@param str string
---@param matched_indices number[] table returned from fuzzy_match
---@param text_prefix string regular text prefix
---@param highlight_prefix string highlighted text prefix
---@return string
local function get_highlighted_string(str, matched_indices, text_prefix, highlight_prefix)
    local result = buffer.new()
    local current_mode = nil -- Track current color mode

    for i = 1, #str do
        local should_highlight = matched_indices[i]

        -- Only add escape sequence if mode changes
        if should_highlight and current_mode ~= "highlight" then
            result:put(highlight_prefix)
            current_mode = "highlight"
        elseif not should_highlight and current_mode ~= "normal" then
            result:put(text_prefix)
            current_mode = "normal"
        end

        result:put(str:sub(i, i))
    end

    return tostring(result)
end

---Searches for a pattern in a string
---@param pattern string
---@param str string
---@param text_prefix number[]|string
---@param highlight_prefix number[]|string
---@return boolean matches True if each character in pattern is found sequentially within str.
---@return integer score Match score. Higher is better match. Value has no intrinsic meaning. Can only compare scores with same search pattern.
---@return string colored_text Modified str with embedded colors that highlights matched characters.
---@nodiscard
---@type fun(pattern:string, str:string, text_prefix:number[]|string, highlight_prefix:number[]|string):boolean, integer, string
local search = memoize(function(pattern, str, text_prefix, highlight_prefix)
    if type(text_prefix) == "table" then
        text_prefix = ansi.to_sequence(text_prefix)
    end
    if type(highlight_prefix) == "table" then
        highlight_prefix = ansi.to_sequence(highlight_prefix)
    end

    local matches, score, matched_indices = fuzzy.fuzzy_match(pattern, str)
    local colored_text = get_highlighted_string(str, matched_indices, text_prefix, highlight_prefix)
    return matches, score, colored_text
end)

return search
