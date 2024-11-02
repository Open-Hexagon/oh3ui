local mouse = require("ui.mouse")
local cursor = require("ui.cursor")
local edge = cursor.edge
local draw_queue = require("ui.draw_queue")

---An extension of hoverbox that additionally tracks mouse clicking and holding.
---@param state table
---@param mode
---|"block" # Blocks the mouse from interacting with anything underneath this sensor (default mode).
---|"pass" # Allows the mouse to interact with sensors underneath this sensor. This sensor will still be active.
---|nil
---@return integer?
return function(state, mode)
    cursor.place()
    draw_queue.mouse_sensor(state, mode or "block", edge.left, edge.top, edge.right, edge.bottom)

    state.clicked = nil

    -- unhold if the mouse is dragged away
    if state.holding and state.exit then
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
