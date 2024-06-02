local state = require("ui.state")
local theme = require("ui.theme")
local ui = require("ui")
local draw_queue = require("ui.draw_queue")

---label element (may auto resize)
---@param text string
---@param wraplimit number?
---@param align love.AlignMode?
return function(text, wraplimit, align)
    if state.allow_automatic_resizing then
        state.auto_width, state.auto_height = draw_queue.get_text_size(text, state.get_font(), wraplimit, align)
    end
    state.update()
    -- undo scale to render text with full resolution
    love.graphics.push()
    love.graphics.scale(1 / ui.scale, 1 / ui.scale)
    draw_queue.text(text, state.get_font(true), state.left * ui.scale, state.top * ui.scale, theme.label_color, wraplimit, align)
    love.graphics.pop()
end
