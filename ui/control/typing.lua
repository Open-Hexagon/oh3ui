local events = require("ui.events")
local utf8 = require("utf8")
local settings = require("ui.settings")
local shared = require("ui.control.shared")

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

local function get_cursor_distance(font, text, char_position)
    return font:getWidth(utf8_sub(text, 1, char_position)) / settings.scale
end

--#region Immediate text edit functions

---Inserts a character into the target
---@param char string
function typing.insert_target(char)
    target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
        .. char
        .. utf8_sub(target.text, target._text_entry_char_position + 1, -1)
    target._text_entry_char_position = target._text_entry_char_position + 1
end

---Deletes all text in the target
function typing.truncate_target()
    target.text = ""
    target._text_entry_char_position = 0
end

---Uses backspace on the target
function typing.baskspace_target()
    target.text = utf8_sub(target.text, 1, target._text_entry_char_position - 1)
        .. utf8_sub(target.text, target._text_entry_char_position + 1, -1)
    target._text_entry_char_position = target._text_entry_char_position - 1

    target._text_entry_text_offset = 0
end

--#endregion

---Returns true if the user is editing any text
---@return boolean
---@nodiscard
function typing.is_editing_any_text()
    -- convert to boolean
    return not not target
end

---Returns true if the user is editing the latest created text entry
---@param state table?
---@return boolean
---@nodiscard
function typing.is_editing(state)
    return target == (state or shared.current_typing_state)
end

---Starts editing text for a state table. Cursor will be placed at the end of the line.
---@param entry_state table
function typing.set_target(entry_state)
    entry_state._text_entry_char_position = utf8.len(entry_state.text)
    target = entry_state
end

---Stops editing text the current target
function typing.unset_target()
    target = nil
end

typing.TAB_BACKWARDS = -1
typing.NO_TAB = 0
typing.TAB_FORWARDS = 1

---Evaluates typing events
---@return integer? goto_cell contains the text entry keyboard navigation cell id if, after evaluation, the target was unset
---@return integer tab_direction true if the tab key was used to unset the target
function typing.evaluate()
    if target then
        -- change text and text pos based on events
        for event in events.iterate("^[tk]e") do
            local name = event[1]
            if name == "textinput" then
                typing.insert_target(event[2])
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
                    if target._text_entry_char_position > 0 then
                        if love.keyboard.isDown("lctrl", "rctrl") then
                            target.text = utf8_sub(target.text, target._text_entry_char_position + 1, -1)
                            target._text_entry_char_position = 0
                        else
                            local old_cursor_dist =
                                get_cursor_distance(target_font, target.text, target._text_entry_char_position)

                            target.text = utf8_sub(target.text, 1, target._text_entry_char_position - 1)
                                .. utf8_sub(target.text, target._text_entry_char_position + 1, -1)
                            target._text_entry_char_position = target._text_entry_char_position - 1

                            local new_cursor_dist =
                                get_cursor_distance(target_font, target.text, target._text_entry_char_position)

                            target._text_entry_text_offset = target._text_entry_text_offset
                                + (old_cursor_dist - new_cursor_dist)
                            if target._text_entry_text_offset > 0 then
                                target._text_entry_text_offset = 0
                            end
                        end
                    end
                elseif key == "delete" then
                    if target._text_entry_char_position < utf8.len(target.text) then
                        if love.keyboard.isDown("lctrl", "rctrl") then
                            target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
                        else
                            target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
                                .. utf8_sub(target.text, target._text_entry_char_position + 2, -1)
                        end
                    end
                elseif key == "escape" then
                    -- unsets the target but doesn't move the keyboard selection
                    typing.unset_target()
                    break
                elseif key == "up" then
                    -- unsets the target and reverse tabs the keyboard selection
                    typing.unset_target()
                    return target_cell_id, typing.TAB_BACKWARDS
                elseif key == "tab" or key == "return" or key == "down" then
                    -- unsets the target and tabs the keyboard selection
                    typing.unset_target()
                    return target_cell_id, typing.TAB_FORWARDS
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
    end

    return nil, typing.NO_TAB
end

do
    local mnav = require("ui.control.mouse_navigation")
    local knav = require("ui.control.keyboard_navigation")
    local kba = knav.actions
    local cursor = require("ui.cursor")
    local placement = cursor.placement
    local mask = require("ui.mask")
    local text = require("ui.text")
    local theme = require("ui.theme")
    local draw_queue = require("ui.draw_queue")
    local primitive = require("ui.primitive")

    ---Sets up a text entry. Uses the current sensor and cell ids for interaction.
    ---@param state table
    ---@param sensor_id integer use a specific sensor id
    ---@param cell_id integer use a specific cell id
    function typing.make_text_entry(state, sensor_id, cell_id)
        state.text = state.text or ""
        -- used to offset the entry text in case there's too much text to fit in view
        state._text_entry_text_offset = state._text_entry_text_offset or 0

        shared.current_typing_state = state

        sensor_id = sensor_id or shared.current_sensor_id
        cell_id = cell_id or shared.current_cell_id

        if typing.is_editing(state) then
            target_cell_id = cell_id
            if not mnav.is_hovering(sensor_id) and mnav.holding then
                typing.unset_target()
            end
        else
            -- tell keyboard navigation that this cell is a text entry
            knav.configure_cell_as_text_input(cell_id, state)
            if mnav.get_clicked(sensor_id) or knav.get_action(cell_id) == kba.activate then
                typing.set_target(state)
            end
        end
    end

    ---Text entry element. Draws the latest made text entry.
    ---@param size number font size in pixels
    ---@param hint string? dim background text that appears when there's no text in the entry
    ---@param text_color number[]? override text color
    ---@param hint_color number[]? override hint text color
    ---@param font_path string? override font path
    function typing.draw_text_entry(size, hint, text_color, hint_color, font_path)
        local font = text.get_font(size * settings.scale, font_path or theme.font_path)
        local text_cursor_height = (font:getBaseline() - font:getDescent()) / settings.scale

        cursor.push()
        cursor.auto_reshape = false
        cursor.inset(4)
        mask.push()

        cursor.change_anchor(0, 0.5)
        cursor.height = text_cursor_height
        cursor.place()

        -- draw the hint text only if there is no text in the entry
        if hint and (not shared.current_typing_state.text or #shared.current_typing_state.text == 0) then
            local hint_text_object = text.get_text_object(font, hint, math.huge, "left")
            draw_queue.text(
                hint_text_object,
                placement.left,
                placement.top,
                hint_color or theme.widget_background_brighter
            )
        end

        local text_object = text.get_text_object(font, shared.current_typing_state.text, math.huge, "left")

        if typing.is_editing() then
            -- keep the target font updated because backspace uses get_cursor_distance
            target_font = font

            -- cursor distance from leftmost character
            local cursor_distance = get_cursor_distance(target_font, target.text, target._text_entry_char_position)

            -- cursor distance from left edge of placement
            local cursor_offset = shared.current_typing_state._text_entry_text_offset + cursor_distance

            -- the furthest amount the cursor can be offset
            local cursor_offset_limit = cursor.width - 1

            -- correct state._text_entry_text_offset to make sure cursor is within view
            if cursor_offset < 0 then
                shared.current_typing_state._text_entry_text_offset = shared.current_typing_state._text_entry_text_offset
                    - cursor_offset
            elseif cursor_offset > cursor_offset_limit then
                shared.current_typing_state._text_entry_text_offset = shared.current_typing_state._text_entry_text_offset
                    - (cursor_offset - cursor_offset_limit)
            end

            -- draw the text
            draw_queue.text(
                text_object,
                placement.left + shared.current_typing_state._text_entry_text_offset,
                placement.top,
                text_color or theme.text_color
            )

            -- draw the text cursor
            cursor.x = cursor.x + cursor_offset
            primitive.vline(theme.white, 1)
        else
            draw_queue.text(text_object, placement.left, placement.top, text_color or theme.text_color)
        end

        mask.pop()
        cursor.pop()
    end
end

return typing
