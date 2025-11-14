local events = require("ui.events")
local utf8 = require("utf8")
local settings = require("ui.settings")
local private = require("ui.control.private")
local utf8_sub = require("ui.text.utf8_sub")

local typing = {}

---@alias typing_stop_methods "click_out"|"escape"|"tab_up"|"tab_down"

---The currently active typing state. This used like a sensor or cell id.
---@type table
local current_typing_state

---The last method used to exit the text edit state
---@type typing_stop_methods
local last_interaction_method

local started_editing_state
local stopped_editing_state

local target
local target_font
local target_cell_id

---Timer used to animate the flashing cursor
local cursor_flash_timer = 0

---Gets the +x pixel offset for the cursor
---@param font love.Font
---@param text string
---@param char_position integer
local function get_cursor_distance(font, text, char_position)
    return font:getWidth(utf8_sub(text, 1, char_position)) / settings.scale
end

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
    return target == (state or current_typing_state)
end

---Returns true if user has started editing current or given state
---@param state table
---@return boolean
function typing.started_editing(state)
    return started_editing_state == (state or current_typing_state)
end

---Returns the method that was used to stop editing text if text input was exited
---@param state table
---@return typing_stop_methods?
---@nodiscard
function typing.stopped_editing(state)
    if stopped_editing_state == (state or current_typing_state) then
        return last_interaction_method
    end
    return nil
end

---Starts editing text for a state table. Cursor will be placed at the end of the line.
---@param entry_state table
local function set_target(entry_state)
    entry_state._text_entry_char_position = utf8.len(entry_state.text)
    target = entry_state
    started_editing_state = entry_state
    cursor_flash_timer = 0
end

private.typing_set_target = set_target

---Stops editing text for the current target
---@param method typing_stop_methods
local function unset_target(method)
    last_interaction_method = method
    stopped_editing_state = target
    target = nil
end

--#region private functions
-- These functions are installed into the private table so they're hidden from the user

---Evaluates typing events
---@return integer? goto_cell contains the text entry keyboard navigation cell id if, after evaluation, the target was unset
---@return typing_stop_methods tab_direction direction to tab if needed
---@nodiscard
function private.typing_evaluate()
    started_editing_state = nil
    stopped_editing_state = nil

    if not target then
        return nil, "escape"
    end

    -- change text and text pos based on events
    for event in events.iterate("^[tk]e") do
        local name, is_repeat = event[1], event[4]
        if name == "textinput" then
            private.last_used_control_method = "typing"
            private.typing_insert_character(target, event[2])
            cursor_flash_timer = 0
        elseif name == "keypressed" then
            private.last_used_control_method = "typing"
            local key = event[3]
            if key == "left" then
                if target._text_entry_char_position > 0 then
                    target._text_entry_char_position = target._text_entry_char_position - 1
                end
                cursor_flash_timer = 0
            elseif key == "right" then
                if target._text_entry_char_position < utf8.len(target.text) then
                    target._text_entry_char_position = target._text_entry_char_position + 1
                end
                cursor_flash_timer = 0
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
                cursor_flash_timer = 0
            elseif key == "delete" then
                if target._text_entry_char_position < utf8.len(target.text) then
                    if love.keyboard.isDown("lctrl", "rctrl") then
                        target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
                    else
                        target.text = utf8_sub(target.text, 1, target._text_entry_char_position)
                            .. utf8_sub(target.text, target._text_entry_char_position + 2, -1)
                    end
                end
                cursor_flash_timer = 0
            elseif key == "home" or key == "pageup" then
                target._text_entry_char_position = 0
                cursor_flash_timer = 0
            elseif key == "end" or key == "pagedown" then
                target._text_entry_char_position = utf8.len(target.text)
                cursor_flash_timer = 0
            elseif key == "escape" then
                -- unsets the target but doesn't move the keyboard selection
                unset_target("escape")
                break
            elseif key == "up" then
                -- unsets the target and reverse tabs the keyboard selection
                unset_target("tab_up")
                return target_cell_id, "tab_up"
            elseif key == "down" then
                -- unsets the target and tabs the keyboard selection
                unset_target("tab_down")
                return target_cell_id, "tab_down"
            elseif key == "tab" then
                -- unsets the target and tabs or reverse tabs the keyboard selection
                local tab_method = love.keyboard.isDown("lshift", "rshift") and "tab_up" or "tab_down"
                unset_target(tab_method)
                return target_cell_id, tab_method
            elseif key == "return" then
                -- not spammable
                if not is_repeat then
                    -- unsets the target and tabs the keyboard selection
                    unset_target("tab_down")
                    return target_cell_id, "tab_down"
                end
            end
        -- these events are matched by the filter but are unused
        elseif name == "keyreleased" then
        elseif name == "textedited" then
            -- I don't know what this one does.
        end
    end

    return nil, "escape"
end

function private.typing_evaluate_without_events()
    started_editing_state = nil
    stopped_editing_state = nil
end

--#endregion

do
    local mnav = require("ui.control.mouse_navigation")
    local knav = require("ui.control.keyboard_navigation")
    local kba = knav.actions
    local cursor = require("ui.cursor")
    local placement = cursor.placement
    local text = require("ui.text")
    local theme = require("ui.theme")
    local draw_queue = require("ui.draw_queue")
    local draw_queue_vline = draw_queue.by_cursor.vline
    local draw_queue_text = draw_queue.by_value.text

    ---Sets up a text entry. Uses the current sensor and cell ids for interaction.
    ---@param state table
    ---@param sensor_id integer? use a specific sensor id
    ---@param cell_id integer? use a specific cell id
    ---@param global boolean? if true, makes this text entry accessible from anywhere by keyboard nav, even if a different non-text-entry element is already selected
    function typing.make_text_entry(state, sensor_id, cell_id, global)
        state.text = state.text or ""
        -- used to offset the entry text in case there's too much text to fit in view
        state._text_entry_text_offset = state._text_entry_text_offset or 0

        current_typing_state = state

        sensor_id = sensor_id or mnav.get_current_sensor_id()
        cell_id = cell_id or knav.get_current_cell_id()

        if typing.is_editing(state) then
            target_cell_id = cell_id
            -- ! if a click happens within a single frame, this won't trigger
            if not mnav.is_hovering(sensor_id) and mnav.holding then
                unset_target("click_out")
            end
        else
            -- tell keyboard navigation that this cell is a text entry
            private.keyboard_navigation_configure_cell_as_text_input(cell_id, state, global)
            if mnav.get_clicked(sensor_id) or knav.get_action(cell_id) == kba.activate then
                set_target(state)
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
        draw_queue.by_cursor.push_mask()

        cursor.change_anchor(0, 0.5)
        cursor.height = text_cursor_height
        cursor.place()

        -- draw the hint text only if there is no text in the entry
        if hint and (not current_typing_state.text or #current_typing_state.text == 0) then
            local hint_text_object = text.get_text_object(font, hint, math.huge, "left")
            draw_queue_text(
                hint_text_object,
                placement.left,
                placement.top,
                hint_color or theme.widget_background_brighter
            )
        end

        local text_object = text.get_text_object(font, current_typing_state.text, math.huge, "left")

        if typing.is_editing() then
            -- keep the target font updated because backspace uses get_cursor_distance
            target_font = font

            -- cursor distance from leftmost character
            local cursor_distance = get_cursor_distance(target_font, target.text, target._text_entry_char_position)

            -- cursor distance from left edge of placement
            local cursor_offset = current_typing_state._text_entry_text_offset + cursor_distance

            -- the furthest amount the cursor can be offset
            local cursor_offset_limit = cursor.width - 1

            -- correct state._text_entry_text_offset to make sure cursor is within view
            if cursor_offset < 0 then
                current_typing_state._text_entry_text_offset = current_typing_state._text_entry_text_offset
                    - cursor_offset
            elseif cursor_offset > cursor_offset_limit then
                current_typing_state._text_entry_text_offset = current_typing_state._text_entry_text_offset
                    - (cursor_offset - cursor_offset_limit)
            end

            -- draw the text
            draw_queue_text(
                text_object,
                placement.left + current_typing_state._text_entry_text_offset,
                placement.top,
                text_color or theme.text_color
            )

            -- draw the text cursor
            if cursor_flash_timer < 0.5 then
                cursor.x = cursor.x + cursor_offset
                draw_queue_vline(theme.white, 1)
            end

            -- cursor flash
            cursor_flash_timer = cursor_flash_timer + love.timer.getDelta()
            if cursor_flash_timer > 1 then
                cursor_flash_timer = cursor_flash_timer - 1
            end
        else
            draw_queue_text(text_object, placement.left, placement.top, text_color or theme.text_color)
        end

        draw_queue.pop_mask()
        cursor.pop()
    end
end

return typing
