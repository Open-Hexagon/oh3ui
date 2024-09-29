local cursor = require("ui.cursor")
local edge = cursor.edge
local clickbox = require("ui.element.clickbox")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local slot = require("ui.element.slot")
local WIDTH, HEIGHT = 40, 20

---Toggle switch element. This element ignores the cursor width and height.
---@param state table
return function(state)
    cursor.push()

    cursor.width = WIDTH
    cursor.height = HEIGHT
    cursor.place()

    if clickbox(state) == clickbox.LEFT then
        state.value = not state.value -- not nil = true
    end

    -- base shape
    local radius = cursor.height / 2
    local color = state.value and theme.active_color or theme.rectangle_color
    slot("fill", color)

    -- circle on current state
    state.position = state.position or 0
    if state.value then
        state.position = math.min(cursor.width - radius, state.position + love.timer.getDelta() * 500)
    else
        state.position = math.max(radius, state.position - love.timer.getDelta() * 500)
    end
    local x = edge.left + state.position
    draw_queue.rectangle("fill", x - radius, edge.top, x + radius, edge.bottom, theme.toggle_actuator, radius, radius)

    cursor.pop()
end
