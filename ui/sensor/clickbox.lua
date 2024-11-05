local mouse = require("ui.mouse")
local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")

---An extension of hoverbox that additionally tracks mouse clicking and holding.
---@param state table
---@param mode? "block"|"lazy"|"pass"
---@return integer?
return function(state, mode)
    cursor.place()
    draw_queue.mouse_sensor(state, mode or "block", placement.left, placement.top, placement.right, placement.bottom)

    state.clicked = nil

    -- unhold if the mouse is dragged away
    if state.holding and not state.hovering then
        state.holding = nil
    end

    if state.hovering then
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
