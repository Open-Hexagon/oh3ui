local entry = require("ui.element.entry")
local state = require("ui.state")
local utils = require("tests.utils")
local utf8 = require("utf8")
local test = {}

local entry_state = {}
local x, y

function test.layout()
    state.allow_automatic_resizing = true
    state.width = 100
    state.height = 50
    x, y = state.x, state.y
    entry(entry_state)
    utils.fake_mouse_cursor()
    state.allow_automatic_resizing = false
end

function test.teardown()
    utils.stop_mouse_control()
end

test.sequence = coroutine.create(function()
    utils.start_mouse_control()
    assert(not entry_state.selected, "should not be selected")
    assert(not love.keyboard.hasKeyRepeat(), "should not have key repeat")
    assert(not love.keyboard.hasTextInput(), "should not have text input")
    utils.mouse_x = x
    utils.mouse_y = y
    utils.click()
    coroutine.yield()
    assert(entry_state.selected, "should be selected")
    -- keyrepeat and text input takes another frame
    assert(not love.keyboard.hasKeyRepeat(), "should not have key repeat")
    assert(not love.keyboard.hasTextInput(), "should not have text input")
    coroutine.yield()
    assert(love.keyboard.hasKeyRepeat(), "should have key repeat")
    assert(love.keyboard.hasTextInput(), "should have text input")

    -- test some inputs
    local test_input = {"H", "e", "l", "l", "o", "!", " ", "u", "t", "f", "8", " ", "w", "o", "r", "k", "s", " ", "t", "o", "o", ":", " ", "°"}
    for i = 1, #test_input do
        love.event.push("textinput", test_input[i])
        coroutine.yield()
        assert(utf8.len(entry_state.text) == i, "text length is wrong")
    end
    assert(entry_state.text == "Hello! utf8 works too: °", "text is wrong")
    assert(entry_state.scroll_state.position > 0, "should have scrolled")
    for _ = 1, #test_input do
        love.event.push("keypressed", "left")
        coroutine.yield()
    end
    utils.wait(0.1)  -- wait for interpolation to finish
    assert(entry_state.scroll_state.position == 0, "should have scrolled back")
    for _ = 1, 3 do
        love.event.push("keypressed", "right")
        coroutine.yield()
    end
    love.event.push("keypressed", "backspace")
    coroutine.yield()
    assert(entry_state.text == "Helo! utf8 works too: °", "text is wrong")
    love.event.push("keypressed", "backspace")
    coroutine.yield()
    assert(entry_state.text == "Hlo! utf8 works too: °", "text is wrong")
    love.event.push("keypressed", "backspace")
    coroutine.yield()
    assert(entry_state.text == "lo! utf8 works too: °", "text is wrong")
    love.event.push("keypressed", "backspace")
    coroutine.yield()
    assert(entry_state.text == "lo! utf8 works too: °", "text is wrong")
    for _ = 1, 5 do
        love.event.push("keypressed", "delete")
        coroutine.yield()
    end
    assert(entry_state.text == "tf8 works too: °", "text is wrong")
    for _ = 1, 16 do
        love.event.push("keypressed", "delete")
        coroutine.yield()
    end
    assert(entry_state.text == "", "text is wrong")
    love.event.push("keypressed", "delete")
    coroutine.yield()
    assert(entry_state.text == "", "text is wrong")
    -- should not move in empty text
    assert(entry_state.cursor_pos == 0, "cursor pos is wrong")
    love.event.push("keypressed", "right")
    coroutine.yield()
    assert(entry_state.cursor_pos == 0, "cursor pos is wrong")
    utils.mouse_x = x - 1
    utils.mouse_y = y
    utils.click()
    coroutine.yield()
    coroutine.yield()
    assert(not entry_state.selected, "should not be selected")
    assert(not love.keyboard.hasKeyRepeat(), "should not have key repeat")
    assert(not love.keyboard.hasTextInput(), "should not have text input")
end)

return test
