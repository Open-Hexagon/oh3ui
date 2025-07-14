local events = require("ui.events")
local utf8 = require("utf8")
local settings = require("ui.settings")

local typing = {}

local target
local target_font
local target_cell_id

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

local function insert_character(char)
    target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
        .. char
        .. utf8_sub(target.text, target._text_entry_char_position + 1, -1)
    target._text_entry_char_position = target._text_entry_char_position + 1
end

---Returns true if the user is editing text
---@return boolean
---@nodiscard
function typing.is_editing_any_text()
    -- convert to boolean
    return not not target
end

---Returns true if the user is editing text
---@param state table
---@return boolean
---@nodiscard
function typing.is_editing_this_text(state)
    -- convert to boolean
    return target == state
end

---Starts editing text for a state table. Cursor will be placed at the end of the line.
---@param entry_state table
---@param append_text string? optional text to be appended when the target is set
function typing.set_target(entry_state, append_text)
    entry_state._text_entry_char_position = utf8.len(entry_state.text)
    target = entry_state

    if append_text then
        for _, c in utf8.codes(append_text) do
            insert_character(utf8.char(c))
        end
    end
end

---Stops editing text the current target
function typing.unset_target()
    target = nil
end

---Updates the font and keyboard navigation cell id to be used by typing.evaluate.
---Should be kept updated when editing text to keep the text cursor location accurate.
---@param font love.Font
---@param cell_id integer
function typing.update_evaluation_info(font, cell_id)
    target_font = font
    target_cell_id = cell_id
end

local function get_cursor_distance(font, text, char_position)
    return font:getWidth(utf8_sub(text, 1, char_position)) / settings.scale
end

---Evaluates typing events
---@return integer? goto_cell contains the text entry keyboard navigation cell id if, after evaluation, the target was unset
---@return integer tab_direction true if the tab key was used to unset the target
function typing.evaluate()
    if not target then
        return nil, 0
    end

    -- change text and text pos based on events
    for event in events.iterate("^[tk]e") do
        local name = event[1]
        if name == "textinput" then
            insert_character(event[2])
        elseif name == "keypressed" then
            local key = event[3]
            if key == "left" then
                if target._text_entry_char_position > 0 then
                    target._text_entry_char_position = target._text_entry_char_position - 1
                end
            elseif key == "right" then
                if target._text_entry_char_position < utf8.len(target.text) then
                    target._text_entry_char_position = target._text_entry_char_position + 1
                end
            elseif key == "backspace" then
                -- backspace will modify target._text_entry_text_offset to try to keep the text cursor still
                -- this prevents the cursor from moving to the far left side of the text entry, which makes it so you can't see what you're deleting
                local old_cursor_dist = get_cursor_distance(target_font, target.text, target._text_entry_char_position)

                target.text = utf8_sub(target.text, 1, math.max(target._text_entry_char_position - 1, 0))
                    .. utf8_sub(target.text, target._text_entry_char_position + 1, -1)
                target._text_entry_char_position = target._text_entry_char_position - 1

                local new_cursor_dist = get_cursor_distance(target_font, target.text, target._text_entry_char_position)

                target._text_entry_text_offset = target._text_entry_text_offset + (old_cursor_dist - new_cursor_dist)
                if target._text_entry_text_offset > 0 then
                    target._text_entry_text_offset = 0
                end
            elseif key == "delete" then
                target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
                    .. utf8_sub(target.text, target._text_entry_char_position + 2, -1)
            elseif key == "escape" then
                -- unsets the target but doesn't move the keyboard selection
                typing.unset_target()
                return target_cell_id, 0
                -- unsets the target and reverse tabs the keyboard selection
            elseif key == "up" then
                typing.unset_target()
                return target_cell_id, -1
            elseif key == "tab" or key == "return" or key == "down" then
                -- unsets the target and tabs the keyboard selection
                typing.unset_target()
                return target_cell_id, 1
            elseif key == "home" or key == "pageup" then
                target._text_entry_char_position = 0
            elseif key == "end" or key == "pagedown" then
                target._text_entry_char_position = utf8.len(target.text)
            end
        -- these events are matched by the filter but are unused
        elseif name == "keyreleased" then
        elseif name == "textedited" then
            -- I don't know what this one does.
        end
    end

    return nil, 0
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
