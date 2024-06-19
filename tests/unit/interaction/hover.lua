local hover_interaction = require("ui.interaction.hover")
local rectangle = require("ui.element.rectangle")
local utils = require("tests.utils")
local state = require("ui.state")
local test = {}

local x, y
local hover_state = {}

function test.layout()
    x, y = state.x, state.y
    rectangle()
    -- hover_interaction.check is already used internally to determine state.hovering
    hover_interaction.timer(hover_state, love.timer.getDelta())
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.stop_mouse_control()
end

test.sequence = coroutine.create(function()
    utils.start_mouse_control()
    utils.mouse_x = x
    utils.mouse_y = y
    local start_time = love.timer.getTime()
    while love.timer.getTime() - start_time < 1 do
        coroutine.yield()
        assert(hover_state.hover_timer > 0, "hover timer 0 after hovering")
    end
    assert(hover_state.hover_timer == 1, "hover timer not 1 after hovering for a second")
    utils.mouse_x = x - 1
    start_time = love.timer.getTime()
    while love.timer.getTime() - start_time < 1 do
        coroutine.yield()
        assert(hover_state.hover_timer < 1, "hover timer 1 after stopping hovering")
    end
    assert(hover_state.hover_timer == 0, "hover timer not 0 after not hovering for a second")
end)

return test
