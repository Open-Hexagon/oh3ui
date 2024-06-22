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
end

function test.teardown()
    utils.stop_mouse_control()
end

test.sequence = coroutine.create(function()
    utils.start_mouse_control()
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
end)

return test
