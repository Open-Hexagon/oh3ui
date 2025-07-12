local events = require("ui.events")
local utf8 = require("utf8")
local settings = require("ui.settings")

local typing = {}

local target
local character_whitelist
local target_font

---Returns true if the user is editing text
---@return boolean
---@nodiscard
function typing.is_editing_text()
    -- convert to boolean
    return not not target
end

---Starts editing text for a state table. Cursor will by default be placed at the end of the line.
---@param entry_state table
---@param char_wl string? Pattern to match whitelisted characters. Must match single characters.
---@param use_last_text_position boolean? If true, using a specific target will put the cursor in its last position for that target.
function typing.set_target(entry_state, char_wl, use_last_text_position)
    if use_last_text_position then
        entry_state._text_entry_char_position = entry_state._text_entry_char_position or 0
    else
        entry_state._text_entry_char_position = #entry_state.text
    end
    target = entry_state
    character_whitelist = char_wl or "."
end

---Stops editing text the current target
function typing.unset_target()
    target = nil
end

---@param font love.Font
function typing.update_font(font)
    target_font = font
end

---string.sub but using utf8 chars instead of bytes for the indices
---@param str string
---@param i integer
---@param j integer
---@return string
---@nodiscard
local function utf8_sub(str, i, j)
    i = utf8.offset(str, i) or #str + 1
    if j > 0 then
        j = utf8.offset(str, j + 1) - 1
    end
    return str:sub(i, j)
end

local function get_cursor_distance(font, text, char_position)
    return font:getWidth(utf8_sub(text, 1, char_position))  / settings.scale
end

---Evaluates typing events
function typing.evaluate()
    if not target then
        return
    end

    local text = target.text
    local text_pos = target._text_entry_char_position

    -- change text and text pos based on events
    for event in events.iterate("^[tk]e") do
        local name = event[1]
        if name == "textinput" then
            if string.find(event[2], character_whitelist) then
                text = utf8_sub(text, 1, text_pos) .. event[2] .. utf8_sub(text, text_pos + 1, -1)
                text_pos = text_pos + 1
            end
        elseif name == "keypressed" then
            local key = event[3]
            if key == "left" then
                text_pos = text_pos - 1
            elseif key == "right" then
                text_pos = text_pos + 1
            elseif key == "backspace" then
                -- backspace will modify target._text_entry_text_offset to try to keep the text cursor still
                local old_cursor_dist = get_cursor_distance(target_font, text, text_pos)

                text = utf8_sub(text, 1, math.max(text_pos - 1, 0)) .. utf8_sub(text, text_pos + 1, -1)
                text_pos = text_pos - 1

                local new_cursor_dist = get_cursor_distance(target_font, text, text_pos)
                target._text_entry_text_offset = target._text_entry_text_offset + (old_cursor_dist - new_cursor_dist)
                if target._text_entry_text_offset > 0 then
                    target._text_entry_text_offset = 0
                end
            elseif key == "delete" then
                text = utf8_sub(text, 1, text_pos) .. utf8_sub(text, text_pos + 2, -1)
            end
        elseif name == "textedited" then
            -- Apparently this is also a thing. I don't know what it does.
        end
    end

    -- update text pos, cursor pos and scroll position
    target.text = text

    if target._text_entry_char_position ~= text_pos then
        -- text pos differs, limit to text bounds
        if text_pos > utf8.len(text) then
            text_pos = utf8.len(text)
        elseif text_pos < 0 then
            text_pos = 0
        end

        if target._text_entry_char_position ~= text_pos then
            -- text pos still differs
            -- set text pos
            target._text_entry_char_position = text_pos
        end
    end
end

---Gets the +x value for where the cursor should go for the current target
---@param font love.Font
---@return number?
---@nodiscard
function typing.get_cursor_distance(font)
    if not target then
        return
    end
    return get_cursor_distance(font, target.text, target._text_entry_char_position)
end

return typing
