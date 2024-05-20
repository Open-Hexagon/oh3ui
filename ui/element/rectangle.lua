local state = require("ui.state")
local theme = require("ui.theme")

---rectangle element
---@param mode string? "fill" or "line" (default is "fill")
return function(mode)
    state.update()
    love.graphics.setColor(theme.rectangle_color)
    love.graphics.rectangle(mode or "fill", state.left, state.top, state.width, state.height)
end
