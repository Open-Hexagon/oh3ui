local toggle = require("ui.element.toggle")
local utils = require("tests.utils")
local state = require("ui.state")
local theme = require("ui.theme")
local test = {}

local toggle_state = {}
local toggle_x, toggle_y

function test.layout()
    state.width = 150
    state.height = 50
    -- center pos
    toggle_x, toggle_y = state.x + 75, state.y + 25
    toggle(toggle_state)
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.stop_mouse_control()
end

-- check state and color change on click
test.sequence = coroutine.create(function()
    utils.start_mouse_control()
    local screen_x, screen_y = love.graphics.transformPoint(toggle_x, toggle_y)
    assert(not toggle_state.state, "toggle state not initialized as false")
    -- click next to, not on the thing, shouldn't do anything
    utils.mouse_x = toggle_x - 76
    utils.mouse_y = toggle_y
    utils.click()
    coroutine.yield()
    assert(utils.check_color_at(screen_x, screen_y, theme.rectangle_color), "color should match rectangle color")
    assert(not toggle_state.state, "toggle state should not have changed")
    -- now click on it
    utils.mouse_x = toggle_x
    utils.mouse_y = toggle_y
    utils.click()
    coroutine.yield()
    assert(utils.check_color_at(screen_x, screen_y, theme.active_color), "color should match active color")
    assert(toggle_state.state, "toggle should be on now")
    -- disable again
    utils.click()
    coroutine.yield()
    assert(utils.check_color_at(screen_x, screen_y, theme.rectangle_color), "color should match rectangle color")
    assert(not toggle_state.state, "toggle state should not have changed")

    -- check error condition
    state.width = 50
    state.height = 100
    xpcall(toggle, function(err)
        assert(err == "Toggle element requires more width than height!", "Wrong error message")
    end, toggle_state)
end)

return test
