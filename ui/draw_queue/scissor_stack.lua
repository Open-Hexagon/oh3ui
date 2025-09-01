---The scissor_stack is stack of rectangular areas.
---Draw operations will only act upon the intersection of all areas
---Operates on screen space coordinates

local volatile_data = require("ui.shared_data").volatile

local scissor_stack = {}

---Push an area on the stack
---@param x number
---@param y number
---@param width number
---@param height number
function scissor_stack.push(x, y, width, height)
    love.graphics.intersectScissor(x, y, width, height)

    -- save a snapshot of what the scissor is like now
    volatile_data.mask_index = volatile_data.mask_index + 1
    local snapshot = volatile_data.mask_stack[volatile_data.mask_index]
    if snapshot then
        snapshot[1], snapshot[2], snapshot[3], snapshot[4] = love.graphics.getScissor()
    else
        snapshot = { love.graphics.getScissor() }
    end
    volatile_data.mask_stack[volatile_data.mask_index] = snapshot
end

---Pop an area from the stack
function scissor_stack.pop()
    scissor_stack.revert(volatile_data.mask_index - 1)
end

---@param n integer
function scissor_stack.revert(n)
    if n == 0 then
        love.graphics.setScissor()
    else
        love.graphics.setScissor(unpack(volatile_data.mask_stack[n]))
    end
    volatile_data.mask_index = n
end

return scissor_stack
