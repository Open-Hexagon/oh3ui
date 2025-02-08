local cursor = require("ui.cursor")
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local selection_outline = require("ui.decorator.selection_outline")
local kba = require("ui.control.keyboard_action")
local kb_nav = require("ui.control.keyboard_navigation")
local m_nav = require("ui.control.mouse_navigation")


---Button element with text. Never reshapes the cursor.
---@param state table
---@param text string
---@param font_size number
---@return integer clicked the "clicked" field of the state table
return function(state, text, font_size)
    cursor.place()

    -- draw background and outline
    local button_color
    if m_nav.get_holding() or kb_nav.get_holding() == kba.activate then
        button_color = theme.widget_background_highlight
    elseif m_nav.is_hovering() then
        button_color = theme.widget_background_brighter
    else
        button_color = theme.widget_background
    end

    primitive.rectangle(button_color)
    primitive.rectangle_outline(
        (m_nav.is_hovering() or kb_nav.is_selected()) and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    cursor.push()
    cursor.change_anchor(0.5, 0.5)
    primitive.label(text, font_size, "left", false)
    cursor.pop()

    -- selection_outline()
    if kb_nav.is_selected() then
        selection_outline()
    end

    return state.clicked
end
