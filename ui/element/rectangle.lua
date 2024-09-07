local cursor = require("ui.cursor")
local output = require("ui.cursor.output")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---rectangle element
---@param mode string? "fill" or "line" (default is "fill")
return function(mode)
    cursor.commit()
    draw_queue.rectangle(mode or "fill", output.left, output.top, output.right, output.bottom, theme.rectangle_color)
end
