---The scissor_stack is stack of rectangular areas.
---Draw operations will only act upon the intersection of all areas
---Operates on screen space coordinates

local scissor_stack = {}

-- A stack of scissor snapshots
local snapshot = {}
local index = 0

---Push an area on the stack
---@param x number
---@param y number
---@param width number
---@param height number
function scissor_stack.push(x, y, width, height)
    love.graphics.intersectScissor(x, y, width, height)

    -- save a snapshot of what the scissor is like now
    index = index + 1
    if snapshot[index] then
        snapshot[index][1], snapshot[index][2], snapshot[index][3], snapshot[index][4] = love.graphics.getScissor()
    else
        snapshot[index] = { love.graphics.getScissor() }
    end
end

---Pop an area from the stack
function scissor_stack.pop()
    if index == 0 then
        error("scissor stack underflow")
    end
    index = index - 1
    if index == 0 then
        love.graphics.setScissor()
    else
        love.graphics.setScissor(unpack(snapshot[index]))
    end
end

---Outputs a warning and clears the stack if it was not empty.
function scissor_stack.finish()
    if index ~= 0 then
        print("warning: scissor stack was not empty")
        index = 0
    end
end

return scissor_stack
