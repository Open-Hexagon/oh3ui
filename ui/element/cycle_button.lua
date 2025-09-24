local cursor = require("ui.cursor")
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local selection_outline_set_location = require("ui.element.decorator.selection_outline").set_location
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode

---Button element that cycles between text when left or right clicked.
---Never reshapes the cursor.
---@param state table
---@param font_size number
---@param ... string
---@return integer position the "position" field of the state table
return function(state, font_size, ...)
    local positions = select("#", ...)

    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for cycle button")
        end
        state.position = 1
        state.initialized = true
    end

    mnav.make_sensor(nil, smode.block)

    if not knav.is_repeat() then
        local kb_action = knav.get_action()
        if mnav.get_clicked() == mb.left or kb_action == kba.right or kb_action == kba.activate then
            state.position = state.position + 1
            if state.position > positions then
                state.position = 1
            end
        elseif mnav.get_clicked() == mb.right or kb_action == kba.left then
            state.position = state.position - 1
            if state.position < 1 then
                state.position = positions
            end
        end
    end

    -- draw background and outline
    local button_color
    if mnav.get_holding() or knav.get_holding() then
        button_color = theme.widget_background_highlight
    elseif mnav.is_hovering() then
        button_color = theme.widget_background_brighter
    else
        button_color = theme.widget_background
    end
    primitive.rectangle(button_color)
    primitive.rectangle_outline(
        (mnav.is_hovering() or knav.is_selected()) and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    cursor.push()
    cursor.change_anchor(0.5, 0.5)
    primitive.label(select(state.position, ...), font_size, "left", false)
    cursor.pop()

    if knav.is_selected() then
        selection_outline_set_location()
    end

    return state.position
end
