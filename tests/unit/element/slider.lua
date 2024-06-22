local slider = require("ui.element.slider")
local utils = require("tests.utils")
local state = require("ui.state")
local theme = require("ui.theme")
local test = {}

local slider_state = {}
local slider_x, slider_y
local min, max, step = 0, 10, 1

function test.layout()
    state.width = 200
    state.height = 50
    slider_x, slider_y = state.x, state.y
    slider(slider_state, min, max, step)
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.stop_mouse_control()
end

-- check state and color change on click
test.sequence = coroutine.create(function()
    utils.start_mouse_control()

    -- check drag
    utils.mouse_x = slider_x + 25
    utils.mouse_y = slider_y + 25
    utils.drag(75, 0, 100)
    assert(slider_state.value == 5, "wrong slider value")

    -- set different min/max/step
    min = 3
    max = 9
    step = 0.5
    coroutine.yield()
    assert(slider_state.value == 6, "wrong slider value")

    -- check click
    utils.mouse_x = slider_x + 200
    utils.click()
    coroutine.yield()
    assert(slider_state.value == 9, "wrong slider value")

    -- check limit on other side
    utils.mouse_x = slider_x
    utils.click()
    coroutine.yield()
    assert(slider_state.value == 3, "wrong slider value")

    -- check wheel interaction
    utils.wheel(1)
    coroutine.yield()
    assert(slider_state.value == 3, "shouldn't have changed")
    for i = 1, 12 do
        utils.wheel(-1)
        coroutine.yield()
        assert(slider_state.value == 3 + i / 2, "wrong slider value")
    end
    utils.wheel(-1)
    coroutine.yield()
    assert(slider_state.value == 9, "slider value should not have changed")

    -- test error condition
    state.width = 50
    state.height = 100
    xpcall(slider, function(err)
        assert(err == "slider element requires more width than height!", "Wrong error message")
    end, slider_state, min, max, step)
end)

return test
