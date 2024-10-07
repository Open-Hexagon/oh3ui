local cursor = require("ui.cursor")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local extmath = require("ui.extmath")
local mouse = require("ui.mouse")
local sensor = require("ui.sensor")

local travel_distance = element.toggle_width - element.toggle_height

---Toggle switch element. This element ignores the cursor size will reshape the cursor.
---@param state table
return function(state)
    cursor.push()

    cursor.place(element.toggle_width, element.toggle_height)
    cursor.push()

    if clickbox(state) == mouse.LEFT then
        state.on = not state.on -- not nil = true
    end

    -- base shape
    primitive.slot(state.on and theme.accent_color or theme.toggle_off_background)

    -- normalized position
    state.toggle_position =
        extmath.clamp((state.toggle_position or 0) + 25 * love.timer.getDelta() * (state.on and 1 or -1), 0, 1)

    cursor.change_anchor(0, 0)
    cursor.width = element.toggle_height
    cursor.height = element.toggle_height
    cursor.x = cursor.x + state.toggle_position * travel_distance

    primitive.circle(theme.toggle_actuator)
    primitive.circle_outline(sensor.hovering and theme.toggle_actuator_outline_highlight or theme.toggle_actuator_outline)

    cursor.pop()
    
    cursor.do_auto_reshape()
    return state.on
end
