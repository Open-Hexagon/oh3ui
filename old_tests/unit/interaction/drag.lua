local drag = require("ui.interaction.drag")
local state = require("ui.state")
local rectangle = require("ui.element.rectangle")
local utils = require("tests.utils")

local x, y
local drag_state = {}
local test = {}

function test.layout()
    if x == nil then
        x = state.x
    end
    if y == nil then
        y = state.y
    end
    state.x = x
    state.y = y
    state.width = 200
    state.height = 100
    rectangle()
    x, y = drag.update(drag_state, x, y, x + 200, y + 100)
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.stop_mouse_control()
end

test.sequence = coroutine.create(function()
    utils.start_mouse_control()
    utils.mouse_x = x
    utils.mouse_y = y
    local earlier_x = x
    local earlier_y = y
    utils.drag(100, 100, 10)
    coroutine.yield()
    assert(x == earlier_x + 100, "did not move right amount")
    assert(y == earlier_y + 100, "did not move right amount")
end)

return test
