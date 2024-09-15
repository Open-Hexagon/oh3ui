---An invisible element that tracks mouse clicking and holding

local mouse = require("ui.interaction.mouse")
local cursor = require("ui.cursor")

local clickbox = {
    LEFT = 1,
    RIGHT = 2,
    MIDDLE = 3,
    BACK = 4,
    FORWARD = 5,
}

local meta = {
    __call = function(_, state)
        cursor.update_mouse_intersect()

        state.clicked = nil

        -- unhold if the mouse is dragged away
        if state.holding and cursor.mouse_intersect.exit then
            state.holding = nil
        end

        if cursor.mouse_intersect.hovering then
            if mouse.any.down then
                if state.holding then
                    -- another mouse button was pressed while holding
                    state.holding = nil
                else
                    -- holding with the last pressed button
                    state.holding = mouse.last_down
                end
            end

            -- if the button being held is released, set the clicked field
            if state.holding and mouse[state.holding].up then
                state.clicked = state.holding
                state.holding = nil
            end
        end

        -- return the click state because we can
        return state.clicked
    end,
}

return setmetatable(clickbox, meta)
