local cursor = require("ui.cursor")
local edge = cursor.edge
local click = require("ui.element.click")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---Toggle switch element. This element ignores the cursor width and height.
---@param toggle_state table
return function(toggle_state)
    cursor.push()

    cursor.width = 40
    cursor.height = 20
    cursor.place()

    if click(toggle_state) == click.LEFT then
        toggle_state.on = not toggle_state.on -- not nil = true
    end

    -- base shape
    local radius = cursor.height / 2
    local color = toggle_state.on and theme.active_color or theme.rectangle_color
    draw_queue.rectangle("fill", edge.left, edge.top, edge.right, edge.bottom, color, radius, radius)

    -- circle on current state
    toggle_state.position = toggle_state.position or 0
    if toggle_state.on then
        toggle_state.position = math.min(cursor.width - radius, toggle_state.position + love.timer.getDelta() * 500)
    else
        toggle_state.position = math.max(radius, toggle_state.position - love.timer.getDelta() * 500)
    end
    local x = edge.left + toggle_state.position
    draw_queue.rectangle("fill", x - radius, edge.top, x + radius, edge.bottom, theme.knob_color, radius, radius)

    cursor.pop()
end
