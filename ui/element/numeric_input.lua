local cursor = require("ui.cursor")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local clickbox = require("ui.sensor.clickbox")
local dragbox = require("ui.sensor.dragbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local text = require("ui.text")
local mouse = require("ui.interaction.mouse")
local extmath = require("ui.extmath")

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
    local full_width = math.max(100, cursor.width)
    cursor.place(full_width, element.numeric_input_height)
    cursor.update_mouse_intersect()

    local hovering = cursor.mouse_intersect.hovering
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
    cursor.update_mouse_intersect()
    local dragging = dragbox(state)

    -- stop the mouse from reaching the edges of the screen
    if state.started_dragging then
        love.mouse.setRelativeMode(true)
    elseif state.stopped_dragging then
        love.mouse.setRelativeMode(false)
        -- put the cursor back where it started
        love.mouse.setPosition(love.graphics.transformPoint(state.drag_origin_x, state.drag_origin_y))
    end

    -- change the mouse cursor to <-> when hovering the center
    if cursor.mouse_intersect.enter then
        love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
    elseif cursor.mouse_intersect.exit then
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
        if cursor.mouse_intersect.hovering then
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
            elseif cursor.mouse_intersect.hovering then
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
            elseif cursor.mouse_intersect.hovering then
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
