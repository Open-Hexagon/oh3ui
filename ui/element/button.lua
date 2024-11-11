local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local mask = require("ui.mask")


---Button element. Can optionally contain text.
---Text that doesn't fit in the button gets cropped.
---Never reshapes the cursor.
---@param state table
---@param text string?
return function(state, text)
    clickbox(state)

    -- draw background and outline
    primitive.rectangle(state.holding and theme.widget_background_highlight or theme.widget_background)
    primitive.rectangle_outline(
        state.hovering and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    if text then
        cursor.push()
        cursor.inset(element.button_internal_padding)
        mask.push()
        cursor.change_anchor(0.5, 0.5)
        primitive.label(text)
        mask.pop()
        cursor.pop()
    end

    return state.clicked
end
