local events = require("ui.event_queue")
local area = require("ui.area")

---handle wheel scroll interaction
---@param scroll_state table
return function(scroll_state)
    for event in events.iterate("wheelmoved") do
        if area.is_mouse_inside() then
            local direction = event[3]
            require("ui.interaction.scroll").go_to(scroll_state.target_position - 50 * direction, 0.1, "linear")
        end
    end
end
