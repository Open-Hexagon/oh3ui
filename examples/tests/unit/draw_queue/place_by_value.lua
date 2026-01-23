---@diagnostic disable: param-type-mismatch
local unittest = require("tests.unittest")
local draw_queue = require("ui.draw_queue")
local history = require("tests.history")
local draw = require("ui.draw_queue.draw")
local common = require("tests.unit.draw_queue.misc")

local T = {}

T.set_up_case = common.set_up_case
T.set_up = common.set_up
T.tear_down_case = common.tear_down_case

function T.test_polygon()
    draw_queue.by_value.polygon("line", { 10, 11, 12, 13 }, 1, 0, 0, 10, 0, 10, 20)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 1 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "poly", "line", 0, 0, 10, 0, 10, 20 })
end

function T.test_text()
    local t = {}

    love.graphics.scale(2)
    draw_queue.by_value.text(t, 30, 30, { 10, 11, 12, 13 })
    draw()
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "draw", t, 60, 60 })
    -- stylua: ignore
    unittest.assert_equal_lists(history.get(0), {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    })
end

function T.test_line()
    draw_queue.by_value.line(1, { 10, 11, 12, 13 }, 0, 0, 10, 0, 10, 20)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 1 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "line", 0, 0, 10, 0, 10, 20 })
end

return T
