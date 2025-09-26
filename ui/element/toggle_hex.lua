local cursor = require("ui.cursor")
local placement = cursor.placement
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local extmath = require("ui.extmath")
local draw_queue = require("ui.draw_queue")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local follow = require("ui.effect").follow
local selection_outline_set_location = require("ui.decorator.selection_outline").set_location
local knav = require("ui.control.keyboard_navigation")

local indiameter = element.toggle_height
local diameter = extmath.from_inradius(indiameter, 6)

local inradius = indiameter * 0.5
local radius = diameter * 0.5

local half_radius = radius * 0.5
local travel_distance = element.toggle_width - diameter

local function draw_base_shape(color)
    local x0 = placement.left
    local x1 = placement.left + half_radius
    local x2 = placement.right - half_radius
    local x3 = placement.right

    local y0 = placement.top
    local y1 = placement.top + inradius
    local y2 = placement.bottom

    -- stylua: ignore
    draw_queue.polygon(
        "fill", color, 1,
        x0, y1,
        x1, y0,
        x2, y0,
        x3, y1,
        x2, y2,
        x1, y2
    )
end

---Hexagonal two-position toggle switch element (because funny).
---This element ignores the cursor size and will reshape the cursor.
---@param state table state table
---@return boolean on the "on" field of the state table
return function(state)
    -- calculate normalized toggle position
    state._toggle_actuator_position = follow(state._toggle_actuator_position, state.on and 0.5 or -0.5, 25)

    cursor.push()
    do
        -- establish element size and sensor region
        cursor.place(element.toggle_width, element.toggle_height)
        mnav.make_sensor(nil, smode.block)

        local clicked = mnav.get_clicked()
        if -- toggle state on
            clicked == mb.left -- left click
            or clicked == mb.right -- right click
            or (not knav.is_repeat() and knav.get_action()) -- any non-repeated keyboard action
        then
            state.on = not state.on
        end

        cursor.push()
        do
            draw_base_shape(state.on and theme.accent_color or theme.widget_background)

            -- draw the actuator
            cursor.change_anchor(0.5, 0.5)
            cursor.width = diameter
            cursor.height = diameter
            cursor.x = cursor.x + state._toggle_actuator_position * travel_distance

            primitive.circle(theme.widget_actuator, 6)
            primitive.circle_outline(
                mnav.is_hovering() and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline,
                nil,
                6
            )
        end
        cursor.pop()

        -- keyboard selection outline
        if knav.is_selected() then
            selection_outline_set_location()
        end
    end
    cursor.do_auto_reshape()

    return state.on
end
