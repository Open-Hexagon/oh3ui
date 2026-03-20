local fuzzy = require("extlibs.fts_fuzzy_match")
local buffer = require("string.buffer")
local ansi = require("ui.text.ansi")

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

-- This cache is very similar to the text cache

local search_cache = {}
local search_cache_objects = {}
local search_cache_object_usage = {}
local search_cache_patterns = {}
local search_cache_haystacks = {}
local search_cache_text_prefixes = {}
local search_cache_highlight_prefixes = {}

local function update()
    for i = #search_cache_objects, 1, -1 do
        local cached_object = search_cache_objects[i]
        local pattern = search_cache_patterns[cached_object]
        local str = search_cache_haystacks[cached_object]
        local text_prefix = search_cache_text_prefixes[cached_object]
        local highlight_prefix = search_cache_highlight_prefixes[cached_object]

        if search_cache_object_usage[cached_object] == 0 then
            -- object was not used
            -- remove cache entries
            search_cache[pattern][str][text_prefix][highlight_prefix] = nil

            -- delete tables if they're empty
            if next(search_cache[pattern][str][text_prefix]) == nil then
                search_cache[pattern][str][text_prefix] = nil
                if next(search_cache[pattern][str]) == nil then
                    search_cache[pattern][str] = nil
                    if next(search_cache[pattern]) == nil then
                        search_cache[pattern] = nil
                    end
                end
            end

            search_cache_object_usage[cached_object] = nil
            search_cache_patterns[cached_object] = nil
            search_cache_haystacks[cached_object] = nil
            search_cache_text_prefixes[cached_object] = nil
            search_cache_highlight_prefixes[cached_object] = nil
            table.remove(search_cache_objects, i)
        else
            -- object was used, start counting at 0 again until next time
            search_cache_object_usage[cached_object] = 0
        end
    end
end

local last_update = love.timer.getTime()
local update_interval = 1 -- seconds

---Searches for a pattern in a string
---@param pattern string
---@param str string
---@param text_color number[]
---@param highlight_color number[]
---@return boolean matches True if each character in pattern is found sequentially within str.
---@return integer score Match score. Higher is better match. Value has no intrinsic meaning. Can only compare scores with same search pattern.
---@return string colored_text Modified str with embedded colors that highlights matched characters.
---@nodiscard
local function search(pattern, str, text_color, highlight_color)
    -- update cache in case the update interval has passed
    local time = love.timer.getTime()
    if time - last_update > update_interval then
        last_update = time
        update()
    end

    local text_prefix = ansi.to_sequence(text_color)
    local highlight_prefix = ansi.to_sequence(highlight_color)

    local cached_object, matches, score, matched_indices, colored_text
    if
        search_cache[pattern] == nil
        or search_cache[pattern][str] == nil
        or search_cache[pattern][str][text_prefix] == nil
        or search_cache[pattern][str][text_prefix][highlight_prefix] == nil
    then
        -- search is not cached, run a new one
        matches, score, matched_indices = fuzzy.fuzzy_match(pattern, str)
        colored_text = get_highlighted_string(str, matched_indices, text_prefix, highlight_prefix)
        cached_object = { matches, score, colored_text }

        search_cache[pattern] = search_cache[pattern] or {}
        search_cache[pattern][str] = search_cache[pattern][str] or {}
        search_cache[pattern][str][text_prefix] = search_cache[pattern][str][text_prefix] or {}
        search_cache[pattern][str][text_prefix][highlight_prefix] = cached_object

        table.insert(search_cache_objects, cached_object)
        search_cache_object_usage[cached_object] = 1
        search_cache_patterns[cached_object] = pattern
        search_cache_haystacks[cached_object] = str
        search_cache_text_prefixes[cached_object] = text_prefix
        search_cache_highlight_prefixes[cached_object] = highlight_prefix

        return matches, score, colored_text
    else
        cached_object = search_cache[pattern][str][text_prefix][highlight_prefix]
        search_cache_object_usage[cached_object] = search_cache_object_usage[cached_object] + 1

        ---@diagnostic disable-next-line: redundant-return-value
        return unpack(cached_object)
    end
end

return search
