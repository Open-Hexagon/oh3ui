local draw_queue = require("ui.draw_queue")
local theme = require("ui.theme")

return function()
    draw_queue.set_inline_transform(100, 0)
    draw_queue.rectangle("fill", 50, 50, 100, 100, theme.green, 0, 0, 1)
    draw_queue.set_inline_transform(0, 0)
    draw_queue.rectangle("line", 50, 50, 100, 100, theme.blue, 0, 0, 4)
end
