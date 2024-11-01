local mouse = require("ui.mouse")
local cursor = require("ui.cursor")
local edge = cursor.edge
local sensor = require("ui.sensor")
local draw_queue = require("ui.draw_queue")

---A sensor element that tracks mouse clicking and holding.
---Implicitly does a `cursor place` and `sensor.update_mouse_intersect`.
---@param state table
---@return integer?
return function(state)
    cursor.place()
    -- sensor.update_mouse_intersect()
    -- sensor.push(state)
    draw_queue.mouse_sensor(state, edge.left, edge.top, edge.right, edge.bottom)

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
