---An extension of clickbox that additionally tracks dragging

local mouse = require("ui.interaction.mouse")
local cursor = require("ui.cursor")

---@param state table
---@return integer?
return function(state)
    cursor.place()
    cursor.update_mouse_intersect()

    state.clicked = nil
    state.stopped_dragging = nil
    state.started_dragging = nil

    if state.dragging then
        if mouse.any.up or mouse.any.down then
            -- end dragging
            state.stopped_dragging = state.dragging
            state.dragging = nil
            -- origin values are not cleared since the can be used by a stopped_dragging event! 
            return
        end
    else
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
    end

    if state.holding and mouse.moved then
        -- begin dragging
        state.started_dragging = state.holding
        state.dragging = state.holding
        state.holding = nil
        state.drag_origin_x = mouse.prev_x
        state.drag_origin_y = mouse.prev_y
    end

    -- return the dragging state
    return state.dragging
end
