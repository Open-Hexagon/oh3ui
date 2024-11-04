local cursor = require("ui.cursor")
local edge = cursor.edge
local draw_queue = require("ui.draw_queue")

---A sensor element that tracks mouse hovering, entering, and exiting.
---@param state table
---@param mode? "block"|"lazy"|"pass"
return function(state, mode)
    cursor.place()
    draw_queue.mouse_sensor(state, mode or "block", edge.left, edge.top, edge.right, edge.bottom)
    return state.hovering
end
