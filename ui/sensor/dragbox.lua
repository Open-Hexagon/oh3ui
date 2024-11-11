local mouse = require("ui.mouse")
local cursor = require("ui.cursor")
local placement = cursor.placement
local sensor = require("ui.sensor")
local draw_queue = require("ui.draw_queue")

---Updates the state table with dragging info.
---A referenced is passed to mouse sensor so it can later be called at the end of the frame.
---@param state table
local function update(state)
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
    end

    if state.holding and mouse.moved then
        -- begin dragging
        state.started_dragging = state.holding
        state.dragging = state.holding
        state.holding = nil
        state.drag_origin_x = mouse.x
        state.drag_origin_y = mouse.y
        sensor.do_intersections = false
    end
end

---An extension of clickbox that additionally tracks dragging.
---Disables mouse intersections while dragging.
---@param state table
---@param mode? "block"|"lazy"|"pass"
---@return integer?
return function(state, mode)
    cursor.place()
    draw_queue.mouse_sensor(
        state,
        mode or "block",
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        update
    )
    return state.dragging
end
