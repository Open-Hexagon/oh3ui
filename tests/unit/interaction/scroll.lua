local scroll = require("ui.area.scroll")
local rectangle = require("ui.element.rectangle")
local state = require("ui.state")
local utils = require("tests.utils")
local area = require("ui.area")

local scroll_state_outer = {}
local scroll_state_inner = {}
local overflow_outer
local overflow_inner
local test = {}
local x, y

function test.layout()
    scroll.start(scroll_state_outer, "vertical", 300)
    scroll.start(scroll_state_inner, "horizontal", 400)
    x, y = state.x, state.y
    for _ = 1, 4 do
        for _ = 1, 10 do
            rectangle()
            state.y = state.bottom + 10
        end
        state.y = y
        state.x = state.right + 10
    end

    -- overflow is only defined after .done
    local data = area.get_extra_data()
    scroll.done()
    overflow_inner = data.overflow

    data = area.get_extra_data()
    scroll.done()
    overflow_outer = data.overflow

    utils.fake_mouse_cursor()
    utils.fake_touch_cursors()
end

function test.teardown()
    utils.stop_mouse_control()
    utils.stop_touch_control()
end

test.sequence = coroutine.create(function()
    utils.start_mouse_control()
    utils.start_touch_control()
    utils.mouse_x = x
    utils.mouse_y = y
    assert(scroll_state_outer.position == 0, "position should be initialized at 0")
    assert(scroll_state_inner.position == 0, "position should be initialized at 0")

    -- scroll both areas to threshold with wheel
    local last_pos
    repeat
        last_pos = scroll_state_inner.position
        utils.wheel(-1)
        utils.wait(0.1)
        assert(scroll_state_inner.position ~= "should scroll inner before outer")
    until scroll_state_inner.position == last_pos
    assert(scroll_state_inner.position == overflow_inner, "inner scroll area should be scrolled to threshold")
    repeat
        last_pos = scroll_state_outer.position
        utils.wheel(-1)
        utils.wait(0.1)
        assert(scroll_state_outer.position ~= "should scroll outer now")
    until scroll_state_outer.position == last_pos
    assert(scroll_state_outer.position == overflow_outer, "outer scroll area should be scrolled to threshold")

    -- drag from corner, make sure inner has priority
    utils.mouse_x = x + 400
    utils.mouse_y = y + 300
    -- should not do anything, since it grabs the horizontal scrollbar
    utils.drag(0, -100, 100)
    -- so it should still be at the same position
    assert(scroll_state_inner.position == overflow_inner, "inner scroll area should be scrolled to threshold")
    assert(scroll_state_outer.position == overflow_outer, "outer scroll area should be scrolled to threshold")
    -- this should scroll horizontally
    utils.mouse_x = x + 400
    utils.mouse_y = y + 300
    local scrollbar_width = scroll_state_inner.scrollbar.right - scroll_state_inner.scrollbar.left
    utils.drag(scrollbar_width - 400.001, 0, 200) -- do a tiny bit more to prevent rounding errors
    -- so vertical area should still be at the same position
    assert(scroll_state_outer.position == overflow_outer, "outer scroll area should be scrolled to threshold")
    -- horizontal one should have scrolled back to the beginning
    assert(scroll_state_inner.position == 0, "inner scroll area should be scrolled back")

    -- now scroll back vertically (at the same positon, the other scrollbar should be gone now)
    utils.mouse_x = x + 400
    utils.mouse_y = y + 300
    utils.drag(0, -300, 150)
    -- both should be reset now
    assert(scroll_state_outer.position == 0, "outer scroll area should be scrolled back")
    assert(scroll_state_inner.position == 0, "inner scroll area should be scrolled back")

    -- scroll with touch
    local touch1 = utils.create_touch()
    touch1.x = x + 10
    touch1.y = y + 100
    love.event.push("touchpressed", touch1.id, touch1.x, touch1.y, 0, 0, touch1.pressure)
    coroutine.yield()
    for _ = 1, 9 do
        touch1.y = touch1.y - 10
        coroutine.yield()
        assert(scroll_state_outer.position == y + 100 - touch1.y, "position does not match touch position")
    end

    -- second touch takes over control
    local touch2 = utils.create_touch()
    touch2.x = x + 10
    touch2.y = y + 100
    love.event.push("touchpressed", touch2.id, touch2.x, touch2.y, 0, 0, touch2.pressure)
    coroutine.yield()

    -- position should no longer change with old finger
    last_pos = scroll_state_outer.position
    touch1.y = touch1.y - 10
    coroutine.yield()
    assert(scroll_state_outer.position == last_pos, "position should not have changed")

    -- it should however with the new one
    local start_pos = scroll_state_outer.position
    for _ = 1, 9 do
        touch2.y = touch2.y - 1
        coroutine.yield()
        assert(scroll_state_outer.position == y + 100 - touch2.y + start_pos, "position does not match touch position")
    end
    -- give back control to touch1
    utils.delete_touch(touch2)
    coroutine.yield()
    -- it should not result in changes due to scroll velocity
    last_pos = scroll_state_outer.position
    coroutine.yield()
    assert(scroll_state_outer.position == last_pos, "position should not have changed")

    -- scroll back a bit
    for _ = 1, 9 do
        touch1.y = touch1.y + 10
        coroutine.yield()
    end

    -- stop touching
    utils.delete_touch(touch1)
    -- check for scroll velocity
    assert(scroll_state_outer.velocity > 0, "scroll velocity should be more than 0")
    -- wait until it is no longer moving
    last_pos = nil
    while scroll_state_outer.position ~= last_pos do
        last_pos = scroll_state_outer.position
        coroutine.yield()
    end
    assert(scroll_state_outer.velocity == 0, "scroll velocity should be 0")

    -- reset position
    scroll_state_outer.position = 0

    -- make sure touch scroll does not happen if touch is on scrollbar
    local touch = utils.create_touch()
    touch.x = x + 400
    touch.y = y
    love.event.push("touchpressed", touch.id, touch.x, touch.y, 0, 0, touch.pressure)
    -- love always creates a mousepressed event on touch presses as well
    utils.mouse_x = touch.x
    utils.mouse_y = touch.y
    love.event.push("mousepressed", touch.x, touch.y, 1, true, 1)
    coroutine.yield()
    for _ = 1, 100 do
        touch.y = touch.y + 3
        -- on touch devices the position returned by love.mouse.getPosition generally corresponds to the latest touch
        utils.mouse_x = touch.x
        utils.mouse_y = touch.y
        coroutine.yield()
    end
    -- if touch scroll was used it'd have scrolled in the other direction (towards 0)
    assert(scroll_state_outer.position == overflow_outer, "outer scroll area should be scrolled to threshold")
end)

return test
