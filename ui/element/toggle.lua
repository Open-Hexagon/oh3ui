local state = require("ui.state")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---toggle element
---@param toggle_state table
return function(toggle_state)
    state.update()
    local radius = math.min(state.width, state.height) / 2
    local y = (state.top + state.bottom) / 2
    draw_queue.rectangle("fill", state.left, state.top, state.right, state.bottom, theme.rectangle_color, radius, radius)
end
