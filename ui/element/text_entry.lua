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
---@param hint string? dim background text that shows when there's no text in the entry
---@param char_wl string? Pattern to match whitelisted characters. Must match single characters.
---@param use_last_text_position boolean? If true, using a specific target will put the cursor in its last position for that target.
---@param text_color number[]? override text color
---@param hint_color number[]? override hint text color
---@param sensor_id integer? use a specific sensor id
---@param font_path string? override font path
return function(state, size, hint, char_wl, use_last_text_position, text_color, hint_color, sensor_id, font_path)
    state.text = state.text or ""

    cursor.push()
    cursor.auto_reshape = false

    local hovering = mnav.is_hovering(sensor_id)
    if state._text_entry_hover_prev ~= hovering then
        state._text_entry_hover_prev = hovering
        if hovering then
            love.mouse.setCursor(love.mouse.getSystemCursor("ibeam"))
        else
            love.mouse.setCursor()
        end
    end

    if typing.is_editing_text() then
        if not hovering and mnav.holding then
            typing.unset_target()
        end
    else
        if mnav.get_clicked(sensor_id) then
            typing.set_target(state, char_wl, use_last_text_position)
        end
    end

    local font = text.get_font(size * settings.scale, font_path or theme.font_path)
    local text_cursor_height = (font:getBaseline() - font:getDescent()) / settings.scale

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
    draw_queue.text(text_object, placement.left, placement.top, text_color or theme.text_color)

    if typing.is_editing_text() then
        local cursor_position = typing.get_cursor_position(font)
        cursor.x = cursor.x + cursor_position
        primitive.vline(theme.white, 1)
    end

    mask.pop()
    cursor.pop()
end
