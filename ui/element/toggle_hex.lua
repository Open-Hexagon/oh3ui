local cursor = require("ui.cursor")
local placement = cursor.placement
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local extmath = require("ui.extmath")
local draw_queue = require("ui.draw_queue")
local effect = require("ui.effect")
local selection_outline = require("ui.decorator.selection_outline")
local mb = require("ui.control.mouse_button")
local kb_nav = require("ui.control.keyboard_navigation")
local m_nav = require("ui.control.mouse_navigation")

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
        "fill", color,
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
    state._toggle_actuator_position = effect.follow(state._toggle_actuator_position, state.on and 0.5 or -0.5, 25)

    -- establish element size and sensor region
    local pid = cursor.place(element.toggle_width, element.toggle_height)

    if -- toggle state on
        m_nav.get_clicked() == mb.left -- left click
        or m_nav.get_clicked() == mb.right -- right click
        or (not kb_nav.is_repeat() and kb_nav.get_action()) -- any non-repeated keyboard action
    then
        state.on = not state.on
    end

    -- save hovering state since we want it to apply for the whole toggle, not just the actuator part
    local hovering = m_nav.is_hovering()

    draw_base_shape(state.on and theme.accent_color or theme.widget_background)

    -- keyboard selection outline
    if kb_nav.is_selected() then
        selection_outline()
    end

    -- set actuator location
    cursor.change_anchor(0.5, 0.5)
    cursor.width = diameter
    cursor.height = diameter
    cursor.x = cursor.x + state._toggle_actuator_position * travel_distance

    -- draw the actuator
    primitive.circle(theme.widget_actuator, 6)
    primitive.circle_outline(
        hovering and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline,
        nil,
        6
    )

    cursor.restore_placement(pid)

    return state.on
end
