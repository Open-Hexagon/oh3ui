local area = require("ui.area")
local rectangle = require("ui.element.rectangle")
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
    area.finish()
    draw_queue.take_last_reservation()
    rectangle()
end

return background
