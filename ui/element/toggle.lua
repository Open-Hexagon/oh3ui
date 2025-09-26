local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local element = require("ui.element")
local theme = require("ui.theme")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local knav = require("ui.control.keyboard_navigation")
local follow = require("ui.effect").follow
local selection_outline_set_location = require("ui.decorator.selection_outline").set_location

local travel_distance = element.toggle_width - element.toggle_height

---Two-position toggle switch element.
---This element ignores the cursor size and will reshape the cursor.
---@param state table state table
---@return boolean on the "on" field of the state table
return function(state)
    -- animate normalized position
    state._toggle_actuator_position = follow(state._toggle_actuator_position, state.on and 1 or 0, 25)

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
            -- draw the base shape
            primitive.slot(state.on and theme.accent_color or theme.widget_background)

            -- draw the actuator
            cursor.change_anchor(0, 0)
            cursor.width = element.toggle_height
            cursor.height = element.toggle_height
            cursor.x = cursor.x + state._toggle_actuator_position * travel_distance

            primitive.circle(theme.widget_actuator)
            primitive.circle_outline(
                mnav.is_hovering() and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline
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
