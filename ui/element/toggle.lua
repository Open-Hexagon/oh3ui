local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local mb = require("ui.control.mouse_button")
local kb_nav = require("ui.control.keyboard_navigation")
local m_nav = require("ui.control.mouse_navigation")

local effect = require("ui.effect")
local selection_outline = require("ui.decorator.selection_outline")

local travel_distance = element.toggle_width - element.toggle_height

---Two-position toggle switch element.
---This element ignores the cursor size and will reshape the cursor.
---@param state table state table
---@return boolean on the "on" field of the state table
return function(state)
    -- animate normalized position
    state._toggle_actuator_position = effect.follow(state._toggle_actuator_position, state.on and 1 or 0, 25)

    -- establish element size and sensor region
    local pid = cursor.place(element.toggle_width, element.toggle_height)

    if -- toggle state on
        m_nav.get_clicked() == mb.left -- left click
        or m_nav.get_clicked() == mb.right -- right click
        or (not kb_nav.is_repeat() and kb_nav.get_action()) -- any non-repeated keyboard action
    then
        state.on = not state.on
    end

    -- keyboard selection outline
    if kb_nav.is_selected() then
        selection_outline()
    end

    -- save hovering state since we want it to apply for the whole toggle, not just the actuator part
    local hovering = m_nav.is_hovering()

    -- draw base shape
    primitive.slot(state.on and theme.accent_color or theme.widget_background)

    -- set actuator location
    cursor.change_anchor(0, 0)
    cursor.width = element.toggle_height
    cursor.height = element.toggle_height
    cursor.x = cursor.x + state._toggle_actuator_position * travel_distance

    -- draw the actuator
    primitive.circle(theme.widget_actuator)
    primitive.circle_outline(hovering and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline)

    cursor.restore_placement(pid)

    return state.on
end
