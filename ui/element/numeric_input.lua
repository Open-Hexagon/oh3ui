local cursor = require("ui.cursor")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local clickbox = require("ui.sensor.clickbox")
local dragbox = require("ui.sensor.dragbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local text = require("ui.text")
local mouse = require("ui.mouse")
local extmath = require("ui.extmath")
local sensor = require("ui.sensor")

---Combination number slider and entry with increment buttons.
---TODO add manual keyboard input when element is clicked.
---@param state table
return function(state, min, max, step, format)
    -- first time initialization
    if not state.initialized then
        state.numeric_input_left = {}
        state.numeric_input_right = {}
        state.value = 0
        state.initialized = true
    end

    cursor.push() -- (1)

    -- set base shape
    local full_width = math.max(element.numeric_input_min_width, cursor.width)
    cursor.place(full_width, element.numeric_input_height)
    sensor.update_mouse_intersect()

    local hovering = sensor.hovering
    local center_width = cursor.width - element.numeric_input_lr_button_width * 2

    cursor.auto_reshape = false
    text.wrap = false
    cursor.change_anchor(0.5)

    -- reserve background for later
    draw_queue.reserve()

    cursor.push() -- (2)

    -- center
    cursor.width = center_width
    cursor.place()
    sensor.update_mouse_intersect()
    local dragging = dragbox(state)

    -- stop the mouse from reaching the edges of the screen
    if state.started_dragging then
        love.mouse.setRelativeMode(true)
        sensor.do_intersections = false
    elseif state.stopped_dragging then
        love.mouse.setRelativeMode(false)
        sensor.do_intersections = true
    end

    -- change the mouse cursor to <-> when hovering the center
    if sensor.enter then
        love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
    elseif sensor.exit then
        love.mouse.setCursor()
    end

    -- prevent the mouse from moving when dragging
    if dragging then
        love.mouse.setPosition(love.graphics.transformPoint(state.drag_origin_x, state.drag_origin_y))
    end

    -- draw background
    draw_queue.take_last_reservation()
    if dragging or state.holding then
        -- highlighted background
        cursor.width = full_width
        primitive.rectangle(theme.button_background_highlight)

        state.value = state.value + mouse.dx
    else
        -- normal background
        cursor.width = full_width
        primitive.rectangle(theme.button_background)
        cursor.width = center_width

        -- brighter center
        if sensor.hovering then
            primitive.rectangle(theme.button_background_brighter)
        end
    end

    if hovering or dragging then
        -- left arrow
        cursor.peek()
        cursor.change_anchor(0)
        cursor.width = element.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        if not dragging then
            if clickbox(state.numeric_input_left) then
                state.value = state.value - step
            end
            if state.numeric_input_left.holding then
                primitive.rectangle(theme.button_background_highlight)
            elseif sensor.hovering then
                primitive.rectangle(theme.button_background_brighter)
            end
        end
        primitive.icon("chevron-left", element.numeric_input_text_size)

        -- right arrow
        cursor.peek()
        cursor.change_anchor(1, 0)
        cursor.width = element.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        if not dragging then
            if clickbox(state.numeric_input_right) then
                state.value = state.value + step
            end
            if state.numeric_input_right.holding then
                primitive.rectangle(theme.button_background_highlight)
            elseif sensor.hovering then
                primitive.rectangle(theme.button_background_brighter)
            end
        end
        primitive.icon("chevron-right", element.numeric_input_text_size)
    end

    cursor.pop() -- (2)

    state.value = extmath.clamp(state.value, min or -math.huge, max or math.huge)
    primitive.label(string.format(format or "%f", state.value), 16)
    primitive.rectangle_outline((hovering or dragging) and theme.button_outline_highlight or theme.button_outline)

    cursor.do_auto_reshape() -- (1)
end
