local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")

---Button element with icon. Icons that don't fit get cropped.
---Never reshapes the cursor.
---@param state table
---@param icon_name string
return function(state, icon_name)
    clickbox(state)

    -- draw background and outline
    primitive.rectangle(state.holding and theme.widget_background_highlight or theme.widget_background)
    primitive.rectangle_outline(
        state.hovering and theme.widget_outline_highlight or theme.widget_outline
    )

    -- draw button internals
    cursor.push()
    cursor.inset(element.button_internal_padding)
    primitive.push_mask()
    cursor.change_anchor(0.5, 0.5)
    primitive.icon(icon_name)
    primitive.pop_mask()
    cursor.pop()

    return state.clicked
end
