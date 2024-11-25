local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")

-- This sensor doesn't need an update function

---A sensor element that tracks mouse hovering.
---
---This element makes these fields in the state table:
--- - `hovering`
---@param state table
---@param mode? "block"|"lazy"|"pass"
return function(state, mode)
    cursor.place()
    draw_queue.mouse_sensor(state, mode or "block", placement.left, placement.top, placement.right, placement.bottom)
    return state.hovering
end
