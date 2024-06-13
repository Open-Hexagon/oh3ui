local rectangle = require("ui.element.rectangle")
local utils = require("tests.utils")
local state = require("ui.state")
local test = {}

local rect_x, rect_y, rect_clicked
local rect_w, rect_h = 250, 125

function test.layout()
    state.width = rect_w
    state.height = rect_h
    rectangle()
    rect_x, rect_y, rect_clicked = state.x, state.y, state.clicked
    -- draw a fake mouse cursor
    utils.fake_mouse_cursor()
end

function test.teardown()
    utils.in_test = false
end

-- This test clicks inside and around the rectangle to determine the correctness of the shape.
test.sequence = coroutine.create(function()
    utils.in_test = true
    -- check most inside positions
    for x = rect_x, rect_x + rect_w, 10 do
        for y = rect_y, rect_y + rect_h, 10 do
            utils.mouse_x = x
            utils.mouse_y = y
            utils.click()
            coroutine.yield()
            assert(rect_clicked, "rect was not clicked")
        end
    end
    -- trace positions around border that are barely outside
    for y_factor = 0, 1 do
        utils.mouse_y = rect_y - 1 + (rect_h + 2) * y_factor
        for x = rect_x - 1, rect_x + rect_w + 1 do
            utils.mouse_x = x
            utils.click()
            coroutine.yield()
            assert(not rect_clicked, "rect was clicked")
        end
    end
    for x_factor = 0, 1 do
        utils.mouse_x = rect_x - 1 + (rect_w + 2) * x_factor
        for y = rect_y - 1, rect_y + rect_h + 1 do
            utils.mouse_y = y
            utils.click()
            coroutine.yield()
            assert(not rect_clicked, "rect was clicked")
        end
    end
end)

return test
