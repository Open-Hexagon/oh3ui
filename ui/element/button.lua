local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local selection_outline = require("ui.element.selection_outline")



---Button element. Can optionally contain text.
---Text that doesn't fit in the button gets cropped.
---Never reshapes the cursor.
---@param state table
---@param text string?
return function(state, text, font_size)
    clickbox(state)

    -- draw background and outline
    primitive.rectangle(state.holding and theme.widget_background_highlight or theme.widget_background)
    primitive.rectangle_outline(
        (state.hovering or state.kb_selected) and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    if text then
        cursor.push()
        cursor.change_anchor(0.5, 0.5)
        primitive.label(text, font_size)
        cursor.pop()
    end

    if state.kb_selected then
        selection_outline()
    end

    return state.clicked
end
