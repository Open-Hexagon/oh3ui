local wrapping_cache = {}
local wrapped_strings = {}
local wrapped_string_usage = {}
local wrapped_string_fonts = {}
local wrapped_string_originals = {}
local wrapped_string_limits = {}

local function update()
    for i = #wrapped_strings, 1, -1 do
        local wrapped_string = wrapped_strings[i]
        local font = wrapped_string_fonts[wrapped_string]
        local unwrapped_string = wrapped_string_originals[wrapped_string]
        local wrap_limit = wrapped_string_limits[wrapped_string]

        if wrapped_string_usage[wrapped_string] == 0 then
            -- string was not used
            -- remove cache entries
            wrapping_cache[font][unwrapped_string][wrap_limit] = nil

            -- delete tables if they're empty
            if next(wrapping_cache[font][unwrapped_string]) == nil then
                wrapping_cache[font][unwrapped_string] = nil
                if next(wrapping_cache[font]) == nil then
                    wrapping_cache[font] = nil
                end
            end

            wrapped_string_usage[wrapped_string] = nil
            wrapped_string_fonts[wrapped_string] = nil
            wrapped_string_originals[wrapped_string] = nil
            wrapped_string_limits[wrapped_string] = nil
            table.remove(wrapped_strings, i)
        else
            -- string was used, start counting at 0 again until next time
            wrapped_string_usage[wrapped_string] = 0
        end
    end
end

local last_update = love.timer.getTime()
local update_interval = 1 -- seconds

---Converts a string into a wrapped string where line breaks have been inserted where wrapping would have occurred.
---Mainly used to wrap text at one scale but display it at another scale.
---Scaling the wrap limit alongside the font size doesn't actually work because
---scaling a font by 2x doesn't actually make it exactly 2x wider.
---This is due to pixel rounding and kerning effects.
---@param font love.Font
---@param str string
---@param wrap_limit number
---@return string
---@nodiscard
local function get_wrapped_text(font, str, wrap_limit)
    -- update cache in case the update interval has passed
    local time = love.timer.getTime()
    if time - last_update > update_interval then
        last_update = time
        update()
    end

    local wrapped_string, _, wrapped_text_table
    if
        wrapping_cache[font] == nil
        or wrapping_cache[font][str] == nil
        or wrapping_cache[font][str][wrap_limit] == nil
    then
        _, wrapped_text_table = font:getWrap(str, wrap_limit)
        wrapped_string = table.concat(wrapped_text_table, "\n")

        wrapping_cache[font] = wrapping_cache[font] or {}
        wrapping_cache[font][str] = wrapping_cache[font][str] or {}
        wrapping_cache[font][str][wrap_limit] = wrapped_string

        table.insert(wrapped_strings, wrapped_string)
        wrapped_string_usage[wrapped_string] = 1
        wrapped_string_fonts[wrapped_string] = font
        wrapped_string_originals[wrapped_string] = str
        wrapped_string_limits[wrapped_string] = wrap_limit
    else
        wrapped_string = wrapping_cache[font][str][wrap_limit]
        wrapped_string_usage[wrapped_string] = wrapped_string_usage[wrapped_string] + 1
    end
    return wrapped_string
end

return get_wrapped_text
