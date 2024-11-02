local cursor = require("ui.cursor")
local edge = cursor.edge
local draw_queue = require("ui.draw_queue")

---A sensor element that tracks mouse hovering, entering, and exiting.
---@param state table
---@param mode
---|"block" # Blocks the mouse from interacting with anything underneath this sensor (default mode).
---|"pass" # Allows the mouse to interact with sensors underneath this sensor. This sensor will still be active.
---|nil
return function(state, mode)
    cursor.place()
    draw_queue.mouse_sensor(state, mode or "block", edge.left, edge.top, edge.right, edge.bottom)
    return state.hovering
end
