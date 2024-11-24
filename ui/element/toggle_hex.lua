local cursor = require("ui.cursor")
local placement = cursor.placement
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local extmath = require("ui.extmath")
local draw_queue = require("ui.draw_queue")
local mouse = require("ui.mouse")
local effect = require("ui.effect")
local selection_outline = require("ui.element.selection_outline")

local indiameter = element.toggle_height
local diameter = extmath.from_inradius(indiameter, 6)

local inradius = indiameter * 0.5
local radius = diameter * 0.5

local half_radius = radius * 0.5
local travel_distance = element.toggle_width - diameter

---Hexagonal two-position toggle switch element (because funny).
---This element ignores the cursor size and will reshape the cursor.
---@param state table
return function(state)
    cursor.push()

    cursor.place(element.toggle_width, element.toggle_height)
    cursor.push()

    if clickbox(state) == mouse.LEFT or state.kb_action then
        state.on = not state.on -- not nil = true
    end

    local x0 = placement.left
    local x1 = placement.left + half_radius
    local x2 = placement.right - half_radius
    local x3 = placement.right

    local y0 = placement.top
    local y1 = placement.top + inradius
    local y2 = placement.bottom

    -- base shape
    -- stylua: ignore
    draw_queue.polygon(
        "fill",
        state.on and theme.accent_color or theme.widget_background,
        x0, y1,
        x1, y0,
        x2, y0,
        x3, y1,
        x2, y2,
        x1, y2
    )

    -- calculate normalized toggle position
    state._toggle_actuator_position = effect.follow(state._toggle_actuator_position, state.on and 0.5 or -0.5, 25)

    cursor.change_anchor(0.5, 0.5)
    cursor.width = diameter
    cursor.height = diameter
    cursor.x = cursor.x + state._toggle_actuator_position * travel_distance

    primitive.circle(theme.widget_actuator, 6)
    primitive.circle_outline(
        (state.hovering or state.kb_selected) and theme.widget_actuator_outline_highlight
        or theme.widget_actuator_outline,
        nil,
        6
    )

    cursor.pop()

    if state.kb_selected then
        selection_outline()
    end

    cursor.do_auto_reshape()
    return state.on
end
