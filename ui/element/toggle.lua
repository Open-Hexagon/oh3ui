local state = require("ui.state")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---toggle element
---@param toggle_state table
return function(toggle_state)
    if state.width < state.height then
        error("Toggle element requires more width than height!")
    end

    state.update()

    -- interaction
    if state.clicked then
        toggle_state.state = not toggle_state.state  -- not nil = true
    end

    -- base shape
    local radius = state.height / 2
    local color = toggle_state.state and theme.active_color or theme.rectangle_color
    draw_queue.rectangle("fill", state.left, state.top, state.right, state.bottom, color, radius, radius)

    -- circle on current state
    toggle_state.position = toggle_state.position or 0
    if toggle_state.state then
        toggle_state.position = math.min(state.width - radius, toggle_state.position + love.timer.getDelta() * 500)
    else
        toggle_state.position = math.max(radius, toggle_state.position - love.timer.getDelta() * 500)
    end
    local x = state.left + toggle_state.position
    draw_queue.rectangle("fill", x - radius, state.top, x + radius, state.bottom, theme.knob_color, radius, radius)
end
