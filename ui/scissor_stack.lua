local scissor_stack = {}

local data = {}
local index = 0

---set current scissor by intersecting all areas on the stack
local function update()
    love.graphics.setScissor()
    for i = 1, index do
        love.graphics.intersectScissor(unpack(data[i]))
    end
end

---push an area on the stack
---@param x number
---@param y number
---@param width number
---@param height number
function scissor_stack.push(x, y, width, height)
    index = index + 1
    data[index] = data[index] or {}
    data[index][1] = x
    data[index][2] = y
    data[index][3] = width
    data[index][4] = height
    update()
end

---pop an area from the stack
function scissor_stack.pop()
    index = index - 1
    update()
end

return scissor_stack
