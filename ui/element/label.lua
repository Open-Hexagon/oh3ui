local state = require("ui.state")
local theme = require("ui.theme")
local ui = require("ui")

---label element (may auto resize)
---@param text string
return function(text)
    local font = state.get_font()
    if state.allow_automatic_resizing then
        state.auto_width = font:getWidth(text)
        state.auto_height = font:getHeight()
    end
    state.update()
    love.graphics.setColor(theme.label_color)
    -- undo scale to render text with full resolution
    love.graphics.push()
    love.graphics.scale(1 / ui.scale, 1 / ui.scale)
    love.graphics.print(text, state.get_font(true), state.left * ui.scale, state.top * ui.scale)
    love.graphics.pop()
end
