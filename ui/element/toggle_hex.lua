local cursor = require("ui.cursor")
local edge = cursor.edge
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local extmath = require("ui.extmath")
local draw_queue = require("ui.draw_queue")
local mouse = require("ui.interaction.mouse")

local indiameter = element.toggle_height
local diameter = extmath.from_inradius(indiameter, 6)

local inradius = indiameter * 0.5
local radius = diameter * 0.5

local half_radius = radius * 0.5
local travel_distance = element.toggle_width - diameter

---Hexagonal toggle switch element (because funny).
---This element ignores the cursor size will reshape the cursor.
---@param state table
return function(state)
    cursor.push()

    cursor.place(element.toggle_width, element.toggle_height)
    cursor.push()

    if clickbox(state) == mouse.LEFT then
        state.on = not state.on -- not nil = true
    end

    local x0 = edge.left
    local x1 = edge.left + half_radius
    local x2 = edge.right - half_radius
    local x3 = edge.right

    local y0 = edge.top
    local y1 = edge.top + inradius
    local y2 = edge.bottom

    -- base shape
    draw_queue.polygon(
        "fill",
        state.on and theme.accent_color or theme.toggle_off_background,
        x0,
        y1,
        x1,
        y0,
        x2,
        y0,
        x3,
        y1,
        x2,
        y2,
        x1,
        y2
    )

    -- calculate normalized toggle position
    state.toggle_position =
        extmath.clamp((state.toggle_position or 0) + 25 * love.timer.getDelta() * (state.on and 1 or -1), -0.5, 0.5)

    cursor.change_anchor(0.5, 0.5)
    cursor.width = diameter
    cursor.height = diameter
    cursor.x = cursor.x + state.toggle_position * travel_distance

    primitive.circle(theme.toggle_actuator, 6)
    primitive.circle_outline(
        cursor.mouse_intersect.hovering and theme.toggle_actuator_outline_highlight or theme.toggle_actuator_outline,
        nil,
        6
    )

    cursor.pop()

    cursor.do_auto_reshape()
    return state.on
end
