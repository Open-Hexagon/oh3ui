local area = require("ui.area")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local background = {}

---start a background area
function background.start()
    area.start()
    -- put background draw here once bounds are known
    draw_queue.reserve()
end

---draw the area background and the contents on top
function background.finish()
    local bounds = area.get_bounds()
    area.finish()
    draw_queue.take_last_reservation()
    draw_queue.rectangle("fill", bounds.left, bounds.top, bounds.right, bounds.bottom, theme.rectangle_color)
end

return background
