local button = require("ui.element.button")
local utils = require("tests.utils")
local state = require("ui.state")
local test = {}

local button_state = {}
local btn_x, btn_y

function test.layout()
    state.allow_automatic_resizing = true
    state.width = 100
    state.height = 50
    btn_x, btn_y = state.x, state.y
    button(button_state, "I am a button!")
    state.allow_automatic_resizing = false
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.stop_mouse_control()
end

-- clicking is tested extensively in rectangle test already, so this one just checks hover animation (text is checked in label test)
test.sequence = coroutine.create(function()
    utils.start_mouse_control()
    assert(button_state.hover_timer == 0, "hover timer not 0 before doing anything")
    utils.mouse_x = btn_x
    utils.mouse_y = btn_y
    local start_time = love.timer.getTime()
    while love.timer.getTime() - start_time < 1 do
        coroutine.yield()
        assert(button_state.hover_timer > 0, "hover timer 0 after hovering")
    end
    assert(button_state.hover_timer == 1, "hover timer not 1 after hovering for a second")
    utils.mouse_x = btn_x - 1
    start_time = love.timer.getTime()
    while love.timer.getTime() - start_time < 1 do
        coroutine.yield()
        assert(button_state.hover_timer < 1, "hover timer 1 after stopping hovering")
    end
    assert(button_state.hover_timer == 0, "hover timer not 0 after not hovering for a second")
end)

return test
