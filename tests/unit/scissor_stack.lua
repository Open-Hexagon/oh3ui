local scissor_stack = require("ui.scissor_stack")
local state = require("ui.state")
local utils = require("tests.utils")

local log = utils.log.new()
local test = {}

function test.layout()
    state.allow_automatic_resizing = true
    log:draw()
    state.allow_automatic_resizing = false
end

test.sequence = coroutine.create(function()
    log:add("Pushing rect")
    scissor_stack.push(10, 10, 10, 10)
    local x, y, w, h = love.graphics.getScissor()
    assert(x == 10, "wrong x")
    assert(y == 10, "wrong y")
    assert(w == 10, "wrong width")
    assert(h == 10, "wrong height")
    log:add("Pushing rect")
    scissor_stack.push(11, 11, 10, 10)
    x, y, w, h = love.graphics.getScissor()
    assert(x == 11, "wrong x")
    assert(y == 11, "wrong y")
    assert(w == 9, "wrong width")
    assert(h == 9, "wrong height")
    log:add("Popping rect")
    scissor_stack.pop()
    x, y, w, h = love.graphics.getScissor()
    assert(x == 10, "wrong x")
    assert(y == 10, "wrong y")
    assert(w == 10, "wrong width")
    assert(h == 10, "wrong height")
    log:add("Popping rect")
    scissor_stack.pop()
    x, y, w, h = love.graphics.getScissor()
    assert(x == nil, "should not have scissor")
    assert(y == nil, "should not have scissor")
    assert(w == nil, "should not have scissor")
    assert(h == nil, "should not have scissor")
end)

return test
