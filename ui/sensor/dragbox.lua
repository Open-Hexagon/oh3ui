local mouse = require("ui.mouse")
local cursor = require("ui.cursor")
local sensor = require("ui.sensor")

---An extension of clickbox that additionally tracks dragging.
---Implicitly does a `cursor place` and `sensor.update_mouse_intersect`.
---Disables mouse intersections while dragging.
---@param state table
---@return integer?
return function(state)
    cursor.place()
    sensor.update_mouse_intersect()

    state.clicked = nil
    state.stopped_dragging = nil
    state.started_dragging = nil

    if state.dragging then
        if mouse.any.up or mouse.any.down then
            -- end dragging
            state.stopped_dragging = state.dragging
            state.dragging = nil
            sensor.do_intersections = true
            -- origin values are not cleared since they can be used by a stopped_dragging event!
            return
        end
    else
        if sensor.hovering then
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
    end

    if state.holding and mouse.moved then
        -- begin dragging
        state.started_dragging = state.holding
        state.dragging = state.holding
        state.holding = nil
        state.drag_origin_x = mouse.prev_x
        state.drag_origin_y = mouse.prev_y
        sensor.do_intersections = false
    end

    -- return the dragging state
    return state.dragging
end
