local state = require("ui.state")
local theme = require("ui.theme")
local ui = require("ui")
local draw_queue = require("ui.draw_queue")

---label element (may auto resize)
---@param text string
return function(text)
    if state.allow_automatic_resizing then
        local font = state.get_font()
        state.auto_width = font:getWidth(text)
        state.auto_height = font:getHeight()
    end
    state.update()
    -- undo scale to render text with full resolution
    love.graphics.push()
    love.graphics.scale(1 / ui.scale, 1 / ui.scale)
    draw_queue.text(text, state.get_font(true), state.left * ui.scale, state.top * ui.scale, theme.label_color)
    love.graphics.pop()
end
