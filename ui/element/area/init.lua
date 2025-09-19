local volatile_data = require("ui.shared_data").volatile
local aeb_stack = volatile_data.aeb_stack

local area_element = {}

---pushes a value to the aeb stack
---@param value any
function area_element.aeb_push(value)
    volatile_data.aeb_index = volatile_data.aeb_index + 1
    aeb_stack[volatile_data.aeb_index] = value
end

---pops a value from the aeb stack
---@return any
function area_element.aeb_pop()
    if volatile_data.aeb_index == volatile_data.aeb_base_index then
        error("area element balance stack is empty")
    end

    local temp = aeb_stack[volatile_data.aeb_index]
    aeb_stack[volatile_data.aeb_index] = nil
    volatile_data.aeb_index = volatile_data.aeb_index - 1

    return temp
end

area_element.scrollbar_thickness = 8
area_element.scrollbar_thickness_inactive = area_element.scrollbar_thickness * 0.5
area_element.minimum_scrollbar_actuator_length = 8
area_element.mouse_wheel_scroll_distance = 10
area_element.view_request_padding = area_element.scrollbar_thickness * 1.5
area_element.view_request_speed = 10 -- this is the reciprocal of the time it takes for the animation
area_element.view_request_scrollbar_cooldown_time = 1.5

return area_element
