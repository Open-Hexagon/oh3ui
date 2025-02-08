local cursor = require("ui.cursor")
local theme = require("ui.theme")
local reserve = require("ui.reserve")
local primitive = require("ui.primitive")
local element = require("ui.element")
local text = require("ui.text")
local mouse = require("ui.control.mouse")
local extmath = require("ui.extmath")
local kba = require("ui.control.keyboard_action")
local kb_nav = require("ui.control.keyboard_navigation")
local selection_outline = require("ui.decorator.selection_outline")

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
        state.numeric_input_left = {}
        state.numeric_input_right = {}
        state.numeric_input_center = {}
        state.value = 0
        state.initialized = true
    end

    cursor.push() -- (1)

    -- set base shape
    local full_width = math.max(element.numeric_input_min_width, cursor.width)
    cursor.place(full_width, element.numeric_input_height)

    local hovering = state.hovering or kb_nav.is_selected()
    local center_width = cursor.width - element.numeric_input_lr_button_width * 2

    cursor.auto_reshape = false
    cursor.change_anchor(0.5)

    -- reserve background for later
    local bg_res_id = reserve.allocate(1)

    cursor.push() -- (2)

    -- center
    cursor.width = center_width
    cursor.place()
    local dragging = nil

    -- stop the mouse from reaching the edges of the screen
    if state.numeric_input_center.started_dragging then
        love.mouse.setRelativeMode(true)
    elseif state.numeric_input_center.stopped_dragging then
        love.mouse.setRelativeMode(false)
    end

    -- change the mouse cursor to <-> when hovering the center
    if state.center_hover_prev ~= state.numeric_input_center.hovering then
        state.center_hover_prev = state.numeric_input_center.hovering
        if state.numeric_input_center.hovering then
            love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
        else
            love.mouse.setCursor()
        end
    end

    -- prevent the mouse from moving when dragging
    if dragging then
        love.mouse.setPosition(
            love.graphics.transformPoint(
                state.numeric_input_center.drag_origin_x,
                state.numeric_input_center.drag_origin_y
            )
        )
    end

    -- draw background
    reserve.take(bg_res_id)
    if dragging or state.numeric_input_center.holding then
        -- highlighted background
        cursor.width = full_width
        primitive.rectangle(theme.widget_background_highlight)

        state.value = state.value + mouse.dx
    else
        -- normal background
        cursor.width = full_width
        primitive.rectangle(theme.widget_background)
        cursor.width = center_width

        -- brighter center
        if state.numeric_input_center.hovering then
            primitive.rectangle(theme.widget_background_brighter)
        end
    end

    if hovering or dragging then
        -- left arrow
        cursor.peek()
        cursor.change_anchor(0)
        cursor.width = element.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        local kb_action = kb_nav.get_action()
        local kb_holding = kb_nav.get_holding()
        if not dragging then
            if clickbox(state.numeric_input_left) or kb_action == kba.left then
                state.value = state.value - step
            end
            if state.numeric_input_left.holding or kb_holding == kba.left then
                primitive.rectangle(theme.widget_background_highlight)
            elseif state.numeric_input_left.hovering then
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
            if clickbox(state.numeric_input_right) or kb_action == kba.right then
                state.value = state.value + step
            end
            if state.numeric_input_right.holding or kb_holding == kba.right then
                primitive.rectangle(theme.widget_background_highlight)
            elseif state.numeric_input_right.hovering then
                primitive.rectangle(theme.widget_background_brighter)
            end
        end
        primitive.icon("chevron-right", element.numeric_input_text_size)
    end

    cursor.pop() -- (2)

    state.value = extmath.clamp(state.value, min or -math.huge, max or math.huge)
    primitive.label(string.format(format or "%f", state.value), 16, "left", false)
    primitive.rectangle_outline((hovering or dragging) and theme.widget_outline_highlight or theme.widget_outline)
    hoverbox(state, "pass")

    if kb_nav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)

    return state.value
end
