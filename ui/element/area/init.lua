local volatile_data = require("ui.shared_data").volatile
local aeb_stack = volatile_data.aeb_stack

local area_element = {}

area_element.kind = {
    background = 0xaeb00001,
    collapse = 0xaeb00002,
    scroll = 0xaeb00003,
}

function area_element.aeb_push(n)
    volatile_data.aeb_index = volatile_data.aeb_index + 1
    aeb_stack[volatile_data.aeb_index] = n
end

function area_element.aeb_pop()
    if volatile_data.aeb_index == volatile_data.aeb_base_index then
        error("aeb stack is empty")
    end

    local temp = aeb_stack[volatile_data.aeb_index]
    volatile_data.aeb_index = volatile_data.aeb_index - 1

    return temp
end

return area_element
