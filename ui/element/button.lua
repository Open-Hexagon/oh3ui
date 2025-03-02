local cursor = require("ui.cursor")
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local selection_outline = require("ui.decorator.selection_outline")
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")


---Button element with text. Never reshapes the cursor.
---@param text string
---@param font_size number
---@return mouse_button? clicked the "clicked" field of the state table
return function(text, font_size)
    mnav.make_sensor()

    -- draw background and outline
    local button_color
    if mnav.get_holding() or knav.get_holding() == kba.activate then
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
    primitive.label(text, font_size, "left", false)
    cursor.pop()

    if knav.is_selected() then
        selection_outline()
    end

    return mnav.get_clicked()
end
