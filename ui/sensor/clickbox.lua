---A sensor that tracks mouse clicking and holding

local mouse = require("ui.interaction.mouse")
local cursor = require("ui.cursor")

---@param state table
return function(state)
    cursor.place()
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
end
