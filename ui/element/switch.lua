local cursor = require("ui.cursor")
local projected_placement = cursor.projected_placement
local theme = require("ui.theme")
local econf = require("ui.element_conf")
local follow = require("ui.effect").follow
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local selection_outline = require("ui.decorator.element.selection_outline").set_placement
local draw_queue = require("ui.draw_queue")
local draw_by_cursor = draw_queue.by_cursor

local selection_highlight_speed = 25

---N-position switch
---@param state table state table
---@param custom_sensor integer? If given, element will use this sensor and won't make it's own
---@param ... string position names
---@return integer position the "position" field of the state table
return function(state, custom_sensor, ...)
    local positions = select("#", ...)
    local sid = custom_sensor

    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for switch")
        end
        state.position = 1
        state.initialized = true
    end

    cursor.push() -- (1)

    local full_width = math.max(econf.switch_height, cursor.width)
    cursor.place(full_width, econf.slider_height)

    if not sid then
        sid = mnav.make_sensor()
    end

    cursor.change_anchor(0.5)

    cursor.push() -- (2)

    local sel_bg_res = draw_queue.allocate_reservation(positions)
    local sel_hl_res = draw_queue.allocate_reservation(1)

    -- selection buttons
    local _, section_width = cursor.v_subdivide(positions)
    local left = projected_placement.left
    local right = left + section_width
    local is_inside
    for i = 1, positions do
        is_inside = (left <= mnav.x and mnav.x < right)

        cursor.pop()
        if is_inside and mnav.get_clicked() == mb.left then
            state._switch_selection_highlight_speed = math.abs(state.position - i) * selection_highlight_speed
            state.position = i
        end

        local button_color
        if (is_inside and mnav.get_holding() == mb.left) or i == state.position then
            button_color = theme.widget_background_highlight
        elseif is_inside and mnav.is_hovering() then
            button_color = theme.widget_background_brighter
        else
            button_color = theme.widget_background
        end

        draw_queue.next_takes_reservation(sel_bg_res)
        draw_by_cursor.rectangle(button_color)

        cursor.inset(econf.switch_internal_padding)
        draw_by_cursor.push_mask()
        draw_by_cursor.label(select(i, ...), econf.switch_text_size, "left", false)
        draw_queue.pop_mask()

        left = right
        right = right + section_width
    end

    -- keyboard navigation
    if not knav.is_repeat() then
        local kb_action = knav.get_action()
        if kb_action == kba.left then
            if state.position == 1 then
                state.position = positions
                state._switch_selection_highlight_speed = (positions - 1) * selection_highlight_speed
            else
                state.position = state.position - 1
                state._switch_selection_highlight_speed = selection_highlight_speed
            end
        elseif kb_action == kba.activate or kb_action == kba.right then
            if state.position == positions then
                state.position = 1
                state._switch_selection_highlight_speed = (positions - 1) * selection_highlight_speed
            else
                state.position = state.position + 1
                state._switch_selection_highlight_speed = selection_highlight_speed
            end
        end
    end

    cursor.peek()
    cursor.change_anchor(0)
    cursor.width = section_width
    local base_x = cursor.x
    state._switch_selection_highlight_position =
        follow(state._switch_selection_highlight_position, state.position - 1, state._switch_selection_highlight_speed)
    cursor.x = base_x + state._switch_selection_highlight_position * section_width
    draw_queue.next_takes_reservation(sel_hl_res)
    draw_by_cursor.rectangle(theme.accent_color)

    cursor.pop() -- (2)

    draw_by_cursor.rectangle_outline(
        (mnav.is_hovering() or knav.is_selected()) and theme.accent_color or theme.widget_outline
    )
    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)

    return state.position
end
