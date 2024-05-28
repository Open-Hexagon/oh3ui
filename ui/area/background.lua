local area = require("ui.area")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local background = {}

---start a background area
function background.start()
    area.start()
    -- put background draw here once bounds are known
    draw_queue.placeholder()
end

---draw the area background and the contents on top
function background.done()
    local bounds = area.get_bounds()
    area.done()
    draw_queue.put_next_in_last_placeholder()
    draw_queue.rectangle("fill", bounds.left, bounds.top, bounds.right, bounds.bottom, theme.rectangle_color)
end

return background
