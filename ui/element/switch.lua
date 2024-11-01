local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local sensor = require("ui.sensor")


---N-position switch
return function (state, ...)
    local positions = select("#", ...)
    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for switch")
        end
        for i = 1, positions do
            state[i] = {}
        end
        state.position = 1
        state.initialized = true
    end

    cursor.push() -- (1)

    local full_width = math.max(element.switch_height, cursor.width)
    cursor.place(full_width, element.slider_height)

    cursor.change_anchor(0.5)

    cursor.push() -- (2)

    -- selection buttons
    local hovering = false
    cursor.h_split(positions)
    for i = 1, positions do
        cursor.pop()
        local cb_state = state[i]
        clickbox(cb_state)
        if cb_state.clicked then
            state.position = i
        end

        hovering = hovering or cb_state.hovering

        local button_color
        if i == state.position then
            button_color = theme.accent_color
        elseif cb_state.holding then
            button_color = theme.widget_background_highlight
        elseif cb_state.hovering then
            button_color = theme.widget_background_brighter
        else
            button_color = theme.widget_background
        end

        primitive.rectangle(button_color)

        cursor.inset(element.switch_internal_padding)
        primitive.push_mask()
        primitive.label(select(i, ...), element.switch_text_size)
        primitive.pop_mask()
    end

    cursor.pop() -- (2)
    primitive.rectangle_outline(hovering and theme.accent_color or theme.widget_outline)
    cursor.do_auto_reshape() -- (1)
end