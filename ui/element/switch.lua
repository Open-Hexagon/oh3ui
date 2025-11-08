local cursor = require("ui.cursor")
local theme = require("ui.theme")
local element = require("ui.element")
local follow = require("ui.effect").follow
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local selection_outline = require("ui.decorator.element.selection_outline")
local draw_queue = require("ui.draw_queue")
local draw_by_cursor = draw_queue.by_cursor

local selection_highlight_speed = 25

---N-position switch
---@param state table state table
---@param ... string position names
---@return integer position the "position" field of the state table
return function(state, ...)
    local positions = select("#", ...)

    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for switch")
        end
        state.position = 1
        state.initialized = true
    end

    cursor.push() -- (1)

    local full_width = math.max(element.switch_height, cursor.width)
    cursor.place(full_width, element.slider_height)

    cursor.change_anchor(0.5)

    cursor.push() -- (2)

    local sel_bg_res = draw_queue.allocate_reservation(positions)
    local sel_hl_res = draw_queue.allocate_reservation(1)

    -- selection buttons
    local hovering = knav.is_selected()
    local _, section_width = cursor.h_split(positions)
    for i = 1, positions do
        cursor.pop()
        mnav.make_sensor(nil, smode.block)
        if mnav.get_clicked() == mb.left then
            state._switch_selection_highlight_speed = math.abs(state.position - i) * selection_highlight_speed
            state.position = i
        end

        hovering = hovering or mnav.is_hovering()

        local button_color
        if mnav.get_holding() == mb.left or i == state.position then
            button_color = theme.widget_background_highlight
        elseif mnav.is_hovering() then
            button_color = theme.widget_background_brighter
        else
            button_color = theme.widget_background
        end

        draw_queue.next_takes_reservation(sel_bg_res)
        draw_by_cursor.rectangle(button_color)

        cursor.inset(element.switch_internal_padding)
        draw_by_cursor.push_mask()
        draw_by_cursor.label(select(i, ...), element.switch_text_size, "left", false)
        draw_queue.pop_mask()
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

    draw_by_cursor.rectangle_outline(hovering and theme.accent_color or theme.widget_outline)
    mnav.make_sensor() -- this is so external click functions are correct
    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)

    return state.position
end
