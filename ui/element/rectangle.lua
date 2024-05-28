local state = require("ui.state")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---rectangle element
---@param mode string? "fill" or "line" (default is "fill")
return function(mode)
    state.update()
    draw_queue.rectangle(mode or "fill", state.left, state.top, state.right, state.bottom, theme.rectangle_color)
end
