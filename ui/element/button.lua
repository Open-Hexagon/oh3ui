local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local selection_outline = require("ui.element.selection_outline")
local kba = require("ui.control.keyboard_action")


---Button element with text. Never reshapes the cursor.
---@param state table
---@param text string
---@param font_size number
---@return integer clicked the "clicked" field of the state table
return function(state, text, font_size)
    clickbox(state)

    -- draw background and outline
    local button_color
    if state.holding or state.kb_holding == kba.activate then
        button_color = theme.widget_background_highlight
    elseif state.hovering then
        button_color = theme.widget_background_brighter
    else
        button_color = theme.widget_background
    end
    primitive.rectangle(button_color)
    primitive.rectangle_outline(
        (state.hovering or state.kb_selected) and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    cursor.push()
    cursor.change_anchor(0.5, 0.5)
    primitive.label(text, font_size, "center", false)
    cursor.pop()

    if state.kb_selected then
        selection_outline()
    end

    return state.clicked
end
