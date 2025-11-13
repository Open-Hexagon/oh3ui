local const = require("ui.element.const")
local cursor = require("ui.cursor")
local theme = require("ui.theme")
local draw_by_cursor = require("ui.draw_queue").by_cursor
local selection_outline = require("ui.decorator.element.selection_outline").set_placement
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode


---Checkbox with a intermediate state that can only be accessed by manually setting the position field.
---Will reshape the cursor
---@param state table state table
---@return integer position the "position" field of the state table
return function(state)
    if not state.initialized then
        state.position = 1
        state.initialized = true
    end

    local sid = mnav.declare_sensor_id()

    if not knav.is_repeat() then
        local kb_action = knav.get_action()
        if mnav.get_clicked(sid) == mb.left or kb_action == kba.activate then
            if state.position > 0 then
                state.position = 0
            else
                state.position = 2
            end
        end
    end

    cursor.push()

    local background_color
    if state.position == 0 or state.position == 1 then
        if mnav.is_hovering(sid) then
            background_color = theme.widget_background_brighter
        else
            background_color = theme.widget_background
        end
    else
        background_color = theme.accent_color
    end

    cursor.auto_reshape = true
    draw_by_cursor.icon("square-fill", const.checkbox_size, background_color)
    draw_by_cursor.icon(
        "square",
        const.checkbox_size,
        (mnav.is_hovering() or knav.is_selected()) and theme.widget_outline_highlight or theme.widget_outline
    )
    if state.position > 0 then
        draw_by_cursor.icon(select(state.position, "stop-fill", "check"), const.checkbox_size, theme.white)
    end
    mnav.make_sensor(sid, smode.block)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape()
    return state.position
end
