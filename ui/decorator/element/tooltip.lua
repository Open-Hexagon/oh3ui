local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local mnav = require("ui.control.mouse_navigation")
local knav = require("ui.control.keyboard_navigation")
local extmath = require("ui.extmath")
local typing = require("ui.control.typing")
local draw_queue = require("ui.draw_queue")
local label = draw_queue.by_cursor.label
local ep = require("ui.element_parameters")
local get_last_used_control_method = require("ui.control").get_last_used_control_method

local text_padding = ep.tooltip_text_padding
local tooltip_element_spacing = ep.tooltip_element_spacing + text_padding

local tooltip = {}

local is_active = false
local time = 0
local alpha = 0

local tooltip_text_color = { 0, 0, 0, 0 }

---@param edge "left"|"top"|"right"|"bottom"
---@param str string
---@param font_size number
---@param align love.AlignMode
---@param wrap_limit number?
function tooltip.tooltip(edge, str, font_size, align, wrap_limit)
    if is_active then
        return
    end

    local method = get_last_used_control_method()
    if
        not (
            method == "mouse" and (mnav.is_hovering() or mnav.get_dragging())
            or method == "keyboard" and knav.is_selected()
            or method == "typing" and typing.is_editing()
        )
    then
        return
    end

    is_active = true

    cursor.push()
    cursor.auto_reshape = true

    if edge == "left" then
        cursor.change_anchor(1, 0.5)
        cursor.shift_left(tooltip_element_spacing)
    elseif edge == "top" then
        cursor.change_anchor(0.5, 1)
        cursor.shift_up(tooltip_element_spacing)
    elseif edge == "right" then
        cursor.change_anchor(0, 0.5)
        cursor.shift_right(tooltip_element_spacing)
    elseif edge == "bottom" then
        cursor.change_anchor(0.5, 0)
        cursor.shift_down(tooltip_element_spacing)
    else
        error("invalid tooltip edge")
    end

    local res_id = draw_queue.allocate_reservation(2)

    if wrap_limit then
        cursor.width = wrap_limit
    end

    tooltip_text_color[1], tooltip_text_color[2], tooltip_text_color[3], tooltip_text_color[4] =
        theme.alpha_mod_unpack(theme.text_color, alpha)
    draw_queue.next_as_overlay()
    label(str, font_size, align, not not wrap_limit, tooltip_text_color)

    cursor.outset(text_padding)

    cursor.place()

    local id = draw_queue.make_placement(placement.left, placement.top, placement.right, placement.bottom)
    local shadow_id =
        draw_queue.make_placement(placement.left + 3, placement.top + 3, placement.right + 3, placement.bottom + 3)

    draw_queue.next_takes_reservation(res_id)
    draw_queue.next_as_overlay()
    draw_queue.by_id.rectangle(shadow_id, "fill", 0, 0, 1, 0, 0, 0, alpha * 0.2)

    draw_queue.next_takes_reservation(res_id)
    draw_queue.next_as_overlay()
    draw_queue.by_id.rectangle(id, "fill", 0, 0, 1, theme.alpha_mod_unpack(theme.tooltip_background, alpha))

    draw_queue.next_as_overlay()
    draw_queue.by_id.rectangle_outline(id, 1, 0, 0, theme.alpha_mod_unpack(theme.tooltip_outline, alpha))

    cursor.pop()
end

function tooltip.clean_up()
    if is_active then
        time = time + love.timer.getDelta()
    else
        time = 0
    end

    alpha = extmath.clamp(time * 10 - 5, 0, 1)

    is_active = false
end

return tooltip
