local events = require("ui.event_queue")
local state = require("ui.state")
local area = require("ui.area")

---handle wheel scroll interaction
---@param scroll_state table
return function(scroll_state)
    -- abort if mouse not in any position for interaction
    local x, y = love.mouse.getPosition()
    if not state.is_position_interactable(x, y) then
        return
    end
    for event in events.iterate("wheelmoved") do
        if area.is_mouse_inside() then
            local direction = event[3]
            require("ui.interaction.scroll").go_to(scroll_state.target_position - 50 * direction, 0.1, "linear")
        end
    end
end
