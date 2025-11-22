local stack_data = require("ui.stack_manager.stack_data")
local aeb_stack = stack_data.aeb_stack
local suppress = require("ui.suppress")

local aeb = {
    top_frame = nil,
}

---pushes a value to the aeb stack
---@param value any
function aeb.push(value)
    stack_data.aeb_index = stack_data.aeb_index + 1
    aeb_stack[stack_data.aeb_index] = value
end

---pops a value from the aeb stack
---@return any
---@nodiscard
function aeb.pop()
    if stack_data.aeb_index == stack_data.aeb_base_index then
        error("area element balance stack is empty")
    end

    local temp = aeb_stack[stack_data.aeb_index]
    aeb_stack[stack_data.aeb_index] = nil
    stack_data.aeb_index = stack_data.aeb_index - 1

    return temp
end

---Push an aeb frame header with a name.
---@param name string name of this header
---@param enable_keepout boolean? enable keepout for this and all inner frames
function aeb.push_frame_header(name, enable_keepout)
    aeb.push(name)
    aeb.push(aeb.top_frame)
    aeb.top_frame = stack_data.aeb_index -- put the new top frame

    aeb.push(enable_keepout)
    if enable_keepout then
        suppress.push_keepout()
    end
end

---Pop an aeb frame header.
---@param verify_name string the popped frame must match this name
function aeb.pop_frame_header(verify_name)
    if aeb.pop() then
        suppress.pop_keepout()
    end

    aeb.top_frame = aeb.pop() -- revert the top frame
    local a = aeb.pop()

    if a ~= verify_name then
        error(string.format("%s element was ended with wrong type", verify_name), 2)
    end
end

return aeb
