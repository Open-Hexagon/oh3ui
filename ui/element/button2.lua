local draw_queue = require("ui.draw_queue")
local cursor = require("ui.cursor")
local edge = cursor.edge
local theme = require("ui.theme")

return function(state, text)
    cursor.place()
    draw_queue.rectangle("fill", edge.left, edge.top, edge.right, edge.bottom, theme.button_background, 3, 3)

    cursor.inset(0.5)
    cursor.place()
    draw_queue.rectangle("line", edge.left, edge.top, edge.right, edge.bottom, theme.button_border, 3, 3)
end