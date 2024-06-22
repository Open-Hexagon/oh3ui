local state = require("ui.state")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local drag = require("ui.interaction.drag")
local events = require("ui.events")

---slider element
---@param slider_state table
---@param min number
---@param max number
---@param step number
return function(slider_state, min, max, step)
    if state.width < state.height then
        error("slider element requires more width than height!")
    end

    state.update()

    local radius = state.height / 2
    local half_radius = radius / 2

    -- base shape bar which has half of the knob radius
    draw_queue.rectangle(
        "fill",
        state.left + half_radius,
        state.top + half_radius,
        state.right - half_radius,
        state.bottom - half_radius,
        theme.rectangle_color,
        half_radius,
        half_radius
    )

    -- knob interaction
    slider_state.position = slider_state.position or 0
    local x = state.left + radius + slider_state.position
    local left = drag.update(slider_state, x - radius, state.top, x + radius, state.bottom)
    slider_state.position = left - state.left

    -- proper click (no drag) anywhere on slider
    if state.clicked then
        local mouse_x = love.graphics.inverseTransformPoint(love.mouse.getPosition())
        slider_state.position = mouse_x - state.left - radius
    end

    -- limit position
    local max_position = state.width - 2 * radius
    if slider_state.position < 0 then
        slider_state.position = 0
    elseif slider_state.position > max_position then
        slider_state.position = max_position
    end

    -- get position according to range and step
    local range = max - min
    local relative_value = math.floor(slider_state.position * range / max_position / step + 0.5) * step

    -- wheel interaction
    if state.hovering then
        for event in events.iterate("wheelmoved") do
            local direction = event[3]
            relative_value = relative_value - direction * step
        end
    end

    -- limit value position
    if relative_value > range then
        relative_value = range
    elseif relative_value < 0 then
        relative_value = 0
    end

    -- set actual position and value
    slider_state.position = relative_value * max_position / range
    slider_state.value = relative_value + min

    -- draw knob
    x = state.left + radius + slider_state.position
    draw_queue.rectangle("fill", x - radius, state.top, x + radius, state.bottom, theme.knob_color, radius, radius)
end
