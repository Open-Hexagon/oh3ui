local events = require("ui.events")
local state = require("ui.state")

local drag = {}

---check if pos is in bounds
---@param x number
---@param y number
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return boolean
function drag.is_pos_in_bounds(x, y, left, top, right, bottom)
    return x >= left and x <= right and y >= top and y <= bottom
end

---handle drag interaction for a certain area
---@param drag_state table
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param extra_grabbing_condition boolean?
---@return number
---@return number
---@return number
---@return number
---@return boolean
function drag.update(drag_state, left, top, right, bottom, extra_grabbing_condition)
    if extra_grabbing_condition == nil then
        extra_grabbing_condition = true
    end
    local screen_x, screen_y = love.mouse.getPosition()
    local x, y = love.graphics.inverseTransformPoint(screen_x, screen_y)

    -- handle events
    for event in events.iterate("mouse.*") do
        local name = event[1]
        -- grab when pressing down onto it while it is visible
        if
            name == "mousepressed"
            and drag.is_pos_in_bounds(x, y, left, top, right, bottom)
            and state.is_position_interactable(screen_x, screen_y)
            and extra_grabbing_condition
        then
            -- save the relative position on the bounds to set position later
            drag_state.grabbed_at_x = x - left
            drag_state.grabbed_at_y = y - top
        end
        -- stop grabbing when releasing no matter the cursor position
        if name == "mousereleased" then
            drag_state.grabbed_at_x = nil
            drag_state.grabbed_at_y = nil
        end
    end

    -- calculate current position of moved bounds if grabbed
    local grabbed = drag_state.grabbed_at_x ~= nil and drag_state.grabbed_at_y ~= nil
    if grabbed then
        local width, height = right - left, bottom - top
        left = x - drag_state.grabbed_at_x
        right = left + width
        top = y - drag_state.grabbed_at_y
        bottom = top + height
    end
    return left, top, right, bottom, grabbed
end

return drag
