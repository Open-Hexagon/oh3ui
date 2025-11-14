local shared_data = require("ui.shared_data")
local volatile_data = shared_data.volatile
local control_data = shared_data.control
local aeb_stack = volatile_data.aeb_stack

local aeb = {
    top_frame = nil,
}

local keepout_point_index

---pushes a value to the aeb stack
---@param value any
function aeb.push(value)
    volatile_data.aeb_index = volatile_data.aeb_index + 1
    aeb_stack[volatile_data.aeb_index] = value
end

---pops a value from the aeb stack
---@return any
---@nodiscard
function aeb.pop()
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
function aeb.push_frame_header(name, enable_keepout)
    aeb.push(name)
    aeb.push(aeb.top_frame)
    aeb.top_frame = volatile_data.aeb_index -- put the new top frame

    if not control_data.keepout_enabled and enable_keepout then
        control_data.keepout_enabled = true
        keepout_point_index = volatile_data.aeb_index
    end
end

---Pop an aeb frame header.
---@param verify_name string the popped frame must match this name
function aeb.pop_frame_header(verify_name)
    if keepout_point_index == volatile_data.aeb_index then
        control_data.keepout_enabled = false
        keepout_point_index = nil
    end

    aeb.top_frame = aeb.pop() -- revert the top frame
    local a = aeb.pop()

    if a ~= verify_name then
        error(string.format("%s element was ended with wrong type", verify_name), 2)
    end
end

return aeb
