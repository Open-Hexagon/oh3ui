local cursor = require("ui.cursor")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local extmath = require("ui.extmath")
local mouse = require("ui.mouse")
local effect = require("ui.effect")

local travel_distance = element.toggle_width - element.toggle_height

---Two-position toggle switch element.
---This element ignores the cursor size and will reshape the cursor.
---@param state table
return function(state)
    cursor.push()

    cursor.place(element.toggle_width, element.toggle_height)
    cursor.push()

    if clickbox(state) == mouse.LEFT then
        state.on = not state.on -- not nil = true
    end

    -- base shape
    primitive.slot(state.on and theme.accent_color or theme.widget_background)

    -- normalized position
    state._toggle_actuator_position = effect.follow(state._toggle_actuator_position, state.on and 1 or 0, 25)

    cursor.change_anchor(0, 0)
    cursor.width = element.toggle_height
    cursor.height = element.toggle_height
    cursor.x = cursor.x + state._toggle_actuator_position * travel_distance

    primitive.circle(theme.widget_actuator)
    primitive.circle_outline(
        state.hovering and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline
    )

    cursor.pop()

    cursor.do_auto_reshape()
    return state.on
end
