local typing = require("ui.control.typing")
local draw_queue = require("ui.draw_queue")
local cursor = require("ui.cursor")
local placement = cursor.placement
local text = require("ui.text")
local theme = require("ui.theme")
local settings = require("ui.settings")
local primitive = require("ui.primitive")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")

---Text entry element. Doesn't resize the cursor. Requires a mouse sensor.
---@param state table
---@param size number font size in pixels
---@param hint string? dim background text that appears when there's no text in the entry
---@param char_wl string? Pattern to match whitelisted characters. Must match single characters.
---@param use_last_text_position boolean? If true, using a specific text entry will put the cursor in its last position for that entry.
---@param sensor_id integer? use a specific mouse sensor id for activating this text entry
---@param text_color number[]? override text color
---@param hint_color number[]? override hint text color
---@param font_path string? override font path
return function(state, size, hint, char_wl, use_last_text_position, sensor_id, text_color, hint_color, font_path)
    state.text = state.text or ""

    -- used to offset the entry text in case there's too much text to fit in view
    state._text_entry_text_offset = state._text_entry_text_offset or 0

    cursor.push()
    cursor.auto_reshape = false

    local hovering = mnav.is_hovering(sensor_id)

    local font = text.get_font(size * settings.scale, font_path or theme.font_path)
    local text_cursor_height = (font:getBaseline() - font:getDescent()) / settings.scale

    if typing.is_editing_text() then
        typing.update_font(font)
        if not hovering and mnav.holding then
            typing.unset_target()
        end
    else
        if mnav.get_clicked(sensor_id) then
            typing.set_target(state, char_wl, use_last_text_position)
        end
    end

    cursor.inset(4)
    mask.push()

    cursor.change_anchor(0, 0.5)
    cursor.height = text_cursor_height
    cursor.place()

    if hint and (not state.text or #state.text == 0) then
        local hint_text_object = text.get_text_object(font, hint, math.huge, "left")
        draw_queue.text(hint_text_object, placement.left, placement.top, hint_color or theme.widget_background_brighter)
    end

    local text_object = text.get_text_object(font, state.text, math.huge, "left")

    if typing.is_editing_text() then
        -- cursor distance from leftmost character
        local cursor_distance = typing.get_cursor_distance(font)

        -- cursor distance from left edge of placement
        local cursor_offset = state._text_entry_text_offset + cursor_distance
        local cursor_offset_limit = cursor.width - 1

        -- correct state._text_entry_text_offset to make sure cursor is within view
        if cursor_offset < 0 then
            state._text_entry_text_offset = state._text_entry_text_offset - cursor_offset
        elseif cursor_offset > cursor_offset_limit then
            state._text_entry_text_offset = state._text_entry_text_offset - (cursor_offset - cursor_offset_limit)
        end

        draw_queue.text(
            text_object,
            placement.left + state._text_entry_text_offset,
            placement.top,
            text_color or theme.text_color
        )
        cursor.x = cursor.x + cursor_offset
        primitive.vline(theme.white, 1)
    else
        draw_queue.text(text_object, placement.left, placement.top, text_color or theme.text_color)
    end

    mask.pop()
    cursor.pop()
end
