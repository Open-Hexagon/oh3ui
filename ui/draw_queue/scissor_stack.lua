---The scissor_stack is stack of rectangular areas.
---Draw operations will only act upon the intersection of all areas
---Operates on screen space coordinates

local scissor_stack = {}

local mask_stack = require("ui.shared_data").volatile.mask_stack
local mask_index = 0

---Push an area on the stack
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function scissor_stack.push(x1, y1, x2, y2)
    -- correct for floating point rounding
    x1 = math.floor(x1)
    y1 = math.floor(y1)
    x2 = math.ceil(x2)
    y2 = math.ceil(y2)

    love.graphics.intersectScissor(x1, y1, x2 - x1, y2 - y1)

    -- save a snapshot of what the scissor is like now
    mask_index = mask_index + 1
    local snapshot = mask_stack[mask_index]
    if snapshot then
        snapshot[1], snapshot[2], snapshot[3], snapshot[4] = love.graphics.getScissor()
    else
        snapshot = { love.graphics.getScissor() }
    end
    mask_stack[mask_index] = snapshot
end

---Pop an area from the stack
function scissor_stack.pop()
    scissor_stack.revert(mask_index - 1)
end

---@param n integer
function scissor_stack.revert(n)
    if n == 0 then
        love.graphics.setScissor()
    else
        love.graphics.setScissor(unpack(mask_stack[n]))
    end
    mask_index = n
end

return scissor_stack
