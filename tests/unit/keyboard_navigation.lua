local keyboard_navigation = require("ui.keyboard_navigation")

local test = {}

local left_top
local left_bottom
local right

function test.layout()
    left_top = keyboard_navigation.check(1, 1)
    left_bottom = keyboard_navigation.check(1, 2)
    right = keyboard_navigation.check(2, 1, 2, 2)
end

test.sequence = coroutine.create(function()
    coroutine.yield()
    assert(not left_top, "nothing should be selected yet")
    assert(not left_bottom, "nothing should be selected yet")
    assert(not right, "nothing should be selected yet")
    love.event.push("keypressed", "down")
    coroutine.yield()
    coroutine.yield()
    assert(left_top, "top left should be selected")
    assert(not left_bottom, "bottom left should not be selected")
    assert(not right, "right should not be selected")
    love.event.push("keypressed", "down")
    coroutine.yield()
    coroutine.yield()
    assert(not left_top, "top left should not be selected")
    assert(left_bottom, "bottom left should be selected")
    assert(not right, "right should not be selected")
    love.event.push("keypressed", "right")
    coroutine.yield()
    coroutine.yield()
    assert(not left_top, "top left should not be selected")
    assert(not left_bottom, "bottom left should not be selected")
    assert(right, "right should be selected")
    love.event.push("keypressed", "left")
    coroutine.yield()
    coroutine.yield()
    assert(not left_top, "top left should not be selected")
    assert(left_bottom, "bottom left should be selected")
    assert(not right, "right should not be selected")
    love.event.push("keypressed", "up")
    coroutine.yield()
    coroutine.yield()
    assert(left_top, "top left should be selected")
    assert(not left_bottom, "bottom left should not be selected")
    assert(not right, "right should not be selected")
    love.event.push("keypressed", "up")
    coroutine.yield()
    coroutine.yield()
    assert(left_top, "top left should be selected")
    assert(not left_bottom, "bottom left should not be selected")
    assert(not right, "right should not be selected")
end)

return test
