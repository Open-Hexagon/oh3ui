local cursor = require("ui.cursor")
local edge = cursor.edge
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---rectangle element
---@param mode string? "fill" or "line" (default is "fill")
return function(mode)
    cursor.place()
    draw_queue.rectangle(mode or "fill", edge.left, edge.top, edge.right, edge.bottom, theme.rectangle_color)
end
