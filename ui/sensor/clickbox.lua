local mouse = require("ui.control.mouse")
local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")

---Updates the state table with clicked and holding info.
---A referenced is passed to mouse sensor so it can later be called at the end of the frame.
---
---This element makes these fields in the state table:
--- - `hovering`
--- - `holding`
--- - `clicked`
---@param state table
local function update(state)
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
end

---An extension of hoverbox that additionally tracks mouse clicking and holding.
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
    return state.clicked
end
