local area = require("ui.area")
local theme = require("ui.theme")
local background = {}

---start a background area
function background.start()
    area.start()
end

---draw the area background and the contents on top
function background.done()
    local bounds = area.get_bounds()
    area.done()
    love.graphics.setColor(theme.rectangle_color)
    love.graphics.rectangle("fill", bounds.left, bounds.top, bounds.right - bounds.left, bounds.bottom - bounds.top)
    area.draw()
end

return background
