local click = require("ui.interaction.click")
local utils = require("tests.utils")

local test = {}

function test.layout()
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.stop_mouse_control()
end

test.sequence = coroutine.create(function()
    utils.start_mouse_control()

    -- check default state
    coroutine.yield()
    assert(not click.clicking, "should not be clicking")

    -- check press and release in same position
    love.event.push("mousepressed", 0, 0)
    love.event.push("mousereleased", 0, 0)
    coroutine.yield()
    assert(click.clicking, "should be clicking")

    -- move between press and release barely within move threshold
    love.event.push("mousepressed", 0, 0)
    love.event.push("mousemoved", 10, 0)
    love.event.push("mousemoved", -10, 0)
    love.event.push("mousereleased", 0, 0)
    coroutine.yield()
    assert(click.clicking, "should be clicking")

    -- move between press and release outside move threshold
    love.event.push("mousepressed", 0, 0)
    love.event.push("mousemoved", 10, 1)
    love.event.push("mousereleased", 0, 0)
    coroutine.yield()
    assert(not click.clicking, "should not be clicking")
end)

return test
