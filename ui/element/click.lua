---An invisible element that tracks clicking

local mouse = require("ui.interaction.mouse")
local cursor = require("ui.cursor")

return function(state)
    cursor.update_mouse_intersect()

    state.clicked = nil

    -- unprime if the mouse is dragged away
    if state.primed and cursor.mouse.exit then
        state.primed = nil
    end

    if cursor.mouse.hovering then
        if mouse.any.down then
            if state.primed then
                -- another mouse button was pressed while the primed button was being held
                state.primed = nil
            else
                -- prime the click with the last pressed button
                state.primed = mouse.last_down
            end
        end

        -- if the button matching the primed field is released, set the clicked field 
        if state.primed and mouse[state.primed].up then
            state.clicked = state.primed
            state.primed = nil
        end
    end
end
