-- emulates love2d's graphics transform system

local transform_emulator = {}

local current_matrix = love.math.newTransform()

local stack_index = 0
local stack = {}

function transform_emulator.push()
    stack_index = stack_index + 1
    stack[stack_index] = current_matrix:clone()
end

function transform_emulator.pop()
    current_matrix = stack[stack_index]
    stack[stack_index] = nil
    stack_index = stack_index - 1
end

function transform_emulator.origin()
    current_matrix:reset()
end

function transform_emulator.translate(dx, dy)
    current_matrix:translate(dx, dy)
end

function transform_emulator.scale(sx, sy)
    current_matrix:scale(sx, sy)
end

function transform_emulator.rotate(angle)
    current_matrix:rotate(angle)
end

function transform_emulator.get_matrix()
    return current_matrix:getMatrix()
end

return transform_emulator
