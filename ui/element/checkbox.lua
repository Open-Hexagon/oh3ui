local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local effect = require("ui.effect")
local selection_outline = require("ui.decorator.selection_outline")
local kb_nav = require("ui.control.keyboard_navigation")


---Checkbox with a intermediate state that can only be accessed by manually setting the position field
---@param state table
return function(state)
    cursor.push()
    cursor.place(element.checkbox_size, element.checkbox_size)

    -- draw background and outline
    local button_color
    if state.holding then
        button_color = theme.widget_background_highlight
    elseif state.hovering then
        button_color = theme.widget_background_brighter
    else
        button_color = theme.widget_background
    end
    primitive.rectangle(button_color)
    primitive.rectangle_outline(
        (state.hovering or kb_nav.is_selected()) and theme.widget_outline_highlight or theme.widget_outline
    )

    primitive.icon("three-dots")
    primitive.icon("three-dots")

    if kb_nav.is_selected() then
        selection_outline()
    end
    cursor.do_auto_reshape()

end
