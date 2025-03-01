local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local selection_outline = require("ui.decorator.selection_outline")
local mb = require("ui.control.mouse_button")
local kba = require("ui.control.keyboard_action")
local knav = require("ui.control.keyboard_navigation")

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
        for i = 1, positions do
            state[i] = {}
        end
        state.position = 1
        state.initialized = true
    end

    if not knav.is_repeat() then
        local kb_action = knav.get_action()
        if state.clicked == mb.left or kb_action == kba.right or kb_action == kba.activate then
            state.position = state.position + 1
            if state.position > positions then
                state.position = 1
            end
        elseif state.clicked == mb.right or kb_action == kba.left then
            state.position = state.position - 1
            if state.position < 1 then
                state.position = positions
            end
        end
    end

    clickbox(state)

    -- draw background and outline
    local button_color
    if state.holding or knav.get_holding() then
        button_color = theme.widget_background_highlight
    elseif state.hovering then
        button_color = theme.widget_background_brighter
    else
        button_color = theme.widget_background
    end
    primitive.rectangle(button_color)
    primitive.rectangle_outline(
        (state.hovering or knav.is_selected()) and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    cursor.push()
    cursor.change_anchor(0.5, 0.5)
    primitive.label(select(state.position, ...), font_size, "left", false)
    cursor.pop()

    if knav.is_selected() then
        selection_outline()
    end

    return state.position
end
