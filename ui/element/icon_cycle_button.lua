local cursor = require("ui.cursor")
local theme = require("ui.theme")
local icon = require("ui.draw_queue").by_cursor.icon
local selection_outline = require("ui.decorator.element.selection_outline").set_placement
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode

---An icon that cycles between other icons when left or right clicked.
---Will reshape the cursor.
---@param state table state table
---@param size number icon size in pixels
---@param ... string icon names
---@return integer position the "position" field of the state table
return function(state, size, ...)
    local positions = select("#", ...)
    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for cycle button")
        end
        state.position = 1
        state.initialized = true
    end

    local sid = mnav.declare_sensor_id()

    if not knav.is_repeat() then
        local kb_action = knav.get_action()
        if mnav.get_clicked(sid) == mb.left or kb_action == kba.right or kb_action == kba.activate then
            state.position = state.position + 1
            if state.position > positions then
                state.position = 1
            end
        elseif mnav.get_clicked(sid) == mb.right or kb_action == kba.left then
            state.position = state.position - 1
            if state.position < 1 then
                state.position = positions
            end
        end
    end

    cursor.push()

    local button_color
    if mnav.get_holding(sid) then
        button_color = theme.widget_background_highlight
    elseif knav.get_holding() == kba.activate then
        if mnav.is_hovering(sid) then
            button_color = theme.widget_background_highlight
        else
            button_color = theme.accent_color
        end
    elseif mnav.is_hovering(sid) then
        button_color = theme.accent_color
    else
        button_color = theme.white
    end

    cursor.auto_reshape = "yes"
    icon(select(state.position, ...), size, button_color)
    mnav.make_sensor(sid, smode.block)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape()
    return state.position
end
