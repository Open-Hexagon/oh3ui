local cursor = require("ui.cursor")
local theme = require("ui.theme")
local reserve = require("ui.reserve")
local primitive = require("ui.primitive")
local element = require("ui.element")
local extmath = require("ui.extmath")
local selection_outline = require("ui.decorator.selection_outline")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.button
local knav = require("ui.control.keyboard_navigation")
local kba = knav.action


---Combination number slider and entry with increment buttons.
---This element will reshape the cursor.
---TODO add manual keyboard input when element is clicked.
---@param state table state table
---@param min number min representable number in state.value
---@param max number max representable number in state.value
---@param step number step size for the increment and decrement buttons
---@param format string format string for the number display
---@return number value the "value" field of the state table
return function(state, min, max, step, format)
    -- first time initialization
    if not state.initialized then
        state.value = 0
        state.initialized = true
    end

    cursor.push() -- (1)

    -- set base shape
    local full_width = math.max(element.numeric_input_min_width, cursor.width)
    cursor.place(full_width, element.numeric_input_height)

    local everything_sid = mnav.new_sensor_id()
    local hovering = mnav.is_hovering(everything_sid) or knav.is_selected()
    local center_width = cursor.width - element.numeric_input_lr_button_width * 2

    cursor.auto_reshape = false
    cursor.change_anchor(0.5)

    -- reserve background for later
    local bg_res_id = reserve.allocate(1)

    cursor.push() -- (2)

    -- center
    cursor.width = center_width

    local center_sid = mnav.make_sensor()
    local dragging = mnav.get_dragging(center_sid)

    -- stop the mouse from reaching the edges of the screen
    if mnav.get_started_dragging(center_sid) == mb.left then
        love.mouse.setRelativeMode(true)
    elseif mnav.get_stopped_dragging(center_sid) == mb.left then
        love.mouse.setRelativeMode(false)
    end

    -- change the mouse cursor to <-> when hovering the center
    local center_hovering = mnav.is_hovering(center_sid)
    if state._numeric_input_center_hover_prev ~= center_hovering then
        state._numeric_input_center_hover_prev = center_hovering
        if center_hovering then
            love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
        else
            love.mouse.setCursor()
        end
    end

    -- prevent the mouse from moving when dragging
    if dragging == mb.left then
        love.mouse.setPosition(love.graphics.transformPoint(mnav.press_x, mnav.press_y))
    end

    -- draw background
    reserve.take(bg_res_id)
    if dragging == mb.left then
        -- highlighted background
        cursor.width = full_width
        primitive.rectangle(theme.widget_background_highlight)

        state.value = state.value + mnav.dx
    else
        -- normal background
        cursor.width = full_width
        primitive.rectangle(theme.widget_background)
        cursor.width = center_width

        -- brighter center
        if mnav.is_hovering(center_sid) then
            primitive.rectangle(theme.widget_background_brighter)
        end
    end

    if hovering or dragging == mb.left then
        -- left arrow
        cursor.peek()
        cursor.change_anchor(0)
        cursor.width = element.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        local kb_action = knav.get_action()
        local kb_holding = knav.get_holding()
        if not dragging then
            local left_sid = mnav.make_sensor()
            if mnav.get_clicked(left_sid) == mb.left or kb_action == kba.left then
                state.value = state.value - step
            end
            if mnav.get_holding(left_sid) == mb.left or kb_holding == kba.left then
                primitive.rectangle(theme.widget_background_highlight)
            elseif mnav.is_hovering(left_sid) then
                primitive.rectangle(theme.widget_background_brighter)
            end
        end
        primitive.icon("chevron-left", element.numeric_input_text_size)

        -- right arrow
        cursor.peek()
        cursor.change_anchor(1, 0)
        cursor.width = element.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        if not dragging then
            local right_sid = mnav.make_sensor()
            if mnav.get_clicked(right_sid) == mb.left or kb_action == kba.right then
                state.value = state.value + step
            end
            if mnav.get_holding(right_sid) == mb.left or kb_holding == kba.right then
                primitive.rectangle(theme.widget_background_highlight)
            elseif mnav.is_hovering(right_sid) then
                primitive.rectangle(theme.widget_background_brighter)
            end
        end
        primitive.icon("chevron-right", element.numeric_input_text_size)
    end

    cursor.pop() -- (2)

    state.value = extmath.clamp(state.value, min or -math.huge, max or math.huge)
    primitive.label(string.format(format or "%f", state.value), 16, "left", false)
    primitive.rectangle_outline((hovering or dragging) and theme.widget_outline_highlight or theme.widget_outline)
    mnav.make_sensor("pass", everything_sid)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)

    return state.value
end
