local shared_data = require("ui.shared_data")
local volatile_data = shared_data.volatile
local control_data = shared_data.control
local aeb_stack = volatile_data.aeb_stack

local area_element = {
    top_frame = nil,
}

local keepout_point_index

---pushes a value to the aeb stack
---@param value any
function area_element.aeb_push(value)
    volatile_data.aeb_index = volatile_data.aeb_index + 1
    aeb_stack[volatile_data.aeb_index] = value
end

---pops a value from the aeb stack
---@return any
---@nodiscard
function area_element.aeb_pop()
    if volatile_data.aeb_index == volatile_data.aeb_base_index then
        error("area element balance stack is empty")
    end

    local temp = aeb_stack[volatile_data.aeb_index]
    aeb_stack[volatile_data.aeb_index] = nil
    volatile_data.aeb_index = volatile_data.aeb_index - 1

    return temp
end

---Push an aeb frame header with a name.
---@param name string name of this header
---@param enable_keepout boolean? enable keepout for this and all inner frames
function area_element.aeb_push_frame_header(name, enable_keepout)
    area_element.aeb_push(name)
    area_element.aeb_push(area_element.top_frame)
    area_element.top_frame = volatile_data.aeb_index -- put the new top frame

    if not control_data.keepout_enabled and enable_keepout then
        control_data.keepout_enabled = true
        keepout_point_index = volatile_data.aeb_index
    end
end

---Pop an aeb frame header.
---@param verify_name string the popped frame must match this name
function area_element.aeb_pop_frame_header(verify_name)
    if keepout_point_index == volatile_data.aeb_index then
        control_data.keepout_enabled = false
        keepout_point_index = nil
    end

    area_element.top_frame = area_element.aeb_pop() -- revert the top frame
    local a = area_element.aeb_pop()

    if a ~= verify_name then
        error(string.format("%s element was ended with wrong type", verify_name), 2)
    end
end

area_element.scrollbar_thickness = 8
area_element.scrollbar_thickness_inactive = area_element.scrollbar_thickness * 0.5
area_element.minimum_scrollbar_actuator_length = 8
area_element.mouse_wheel_scroll_distance = 10
area_element.view_request_padding = area_element.scrollbar_thickness * 1.5
area_element.view_request_speed = 10 -- this is the reciprocal of the time it takes for the animation
area_element.view_request_scrollbar_cooldown_time = 1.5
area_element.collapse_speed = 1800

return area_element
