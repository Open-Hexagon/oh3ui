local background = require("ui.area.background")
local rectangle = require("ui.element.rectangle")
local theme = require("ui.theme")
local state = require("ui.state")
local utils = require("tests.utils")

local test = {}

local test_color = { 1, 0, 1, 0 }
local rect_bounds = {}

function test.layout()
    background.start()
    rectangle()
    rect_bounds.left, rect_bounds.top = love.graphics.transformPoint(state.left, state.top)
    rect_bounds.right, rect_bounds.bottom = love.graphics.transformPoint(state.right, state.bottom)
    theme.rectangle_color = test_color
    background.done()
    theme.rectangle_color = nil
end

function test.teardown()
    utils.remove_graphics_callback()
end

-- checks the draw call of the area and makes sure that it has the same bounds as the contents (the rect)
test.sequence = coroutine.create(function()
    utils.add_graphics_callback(function(graphics_fun, ...)
        local color = { love.graphics.getColor() }
        for i = 1, 4 do
            if color[i] ~= test_color[i] then
                -- color does not match, draw call is not part of test
                return
            end
        end
        assert(graphics_fun == "rectangle", "test entry is not a rectangle")
        local mode, x, y, rect_width, rect_height, rx, ry = ...
        assert(mode == "fill", "mode is not fill")
        assert(x == rect_bounds.left, "x position is wrong")
        assert(y == rect_bounds.right, "y position is wrong")
        assert(rect_width == rect_bounds.right - rect_bounds.left, "width is wrong")
        assert(rect_height == rect_bounds.bottom - rect_bounds.top, "height is wrong")
        assert(rx == 0, "x radius is wrong")
        assert(ry == 0, "y radius is wrong")
    end)
end)

return test
