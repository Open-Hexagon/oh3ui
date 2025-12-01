---@diagnostic disable: param-type-mismatch
local unittest = require("tests.unittest")
local draw_queue = require("ui.draw_queue")
local scissor_stack = require("ui.draw_queue.scissor_stack")
local sensor = require("ui.control.sensor")
local history = require("tests.history")
local monkeypatch = require("tests.monkeypatch")
local te = require("tests.transform_emulator")
local draw = require("ui.draw_queue.draw")
local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")
local common = require("tests.unit.draw_queue.misc")
local cursor = require("ui.cursor")

local T = {}

T.set_up_case = common.set_up_case
T.set_up = common.set_up
T.tear_down_case = common.tear_down_case

function T.test_push_mask()
    love.graphics.scale(2)

    cursor.x = 10
    cursor.y = 10
    cursor.width = 20
    cursor.height = 20

    draw_queue.by_cursor.push_mask()
    draw()
    unittest.assert_equal_lists(history.get(0), { "sspush", 20, 20, 60, 60 })
end

function T.test_blank()
    cursor.x = 10
    cursor.y = 10
    cursor.width = 20
    cursor.height = 20

    local p = draw_queue.by_cursor.blank()
    unittest.assert_equal_lists({ draw_data.get_placement(p) }, { 10, 10, 30, 30 })
end

function T.test_rectangle()
    cursor.x = 30
    cursor.y = 31
    cursor.width = 10
    cursor.height = 10

    draw_queue.by_cursor.rectangle({ 10, 11, 12, 13 }, "fill", 3, 2, 4)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 3 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "rect", "fill", 30, 31, 10, 10, 2, 4 })
end

function T.test_rectangle_outline()
    local line_width = 8
    local half_width = line_width * 0.5

    cursor.x = 30
    cursor.y = 31
    cursor.width = 30
    cursor.height = 30

    draw_queue.by_cursor.rectangle_outline({ 10, 11, 12, 13 }, line_width, 3, 2)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(
        history.get(-1),
        { "rect", "line", 30 + half_width, 31 + half_width, 30 - line_width, 30 - line_width, 3, 2 }
    )
end

function T.test_rectangle_inline()
    local line_width = 8
    local half_width = line_width * 0.5

    cursor.x = 30
    cursor.y = 31
    cursor.width = 30
    cursor.height = 30

    draw_queue.by_cursor.rectangle_inline({ 10, 11, 12, 13 }, line_width, 3, 2)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(
        history.get(-1),
        { "rect", "line", 30 - half_width, 31 - half_width, 30 + line_width, 30 + line_width, 3, 2 }
    )
end

function T.test_slot()
    cursor.x = 30
    cursor.y = 31
    cursor.width = 10
    cursor.height = 40
    draw_queue.by_cursor.slot({ 10, 11, 12, 13 }, "fill", 8)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "rect", "fill", 30, 31, 10, 40, 5, 5 })
end

function T.test_slot_outline()
    local line_width = 8
    local half_width = line_width * 0.5

    cursor.x = 30
    cursor.y = 31
    cursor.width = 10
    cursor.height = 40
    draw_queue.by_cursor.slot_outline({ 10, 11, 12, 13 }, line_width)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(
        history.get(-1),
        { "rect", "line", 30 + half_width, 31 + half_width, 10 - line_width, 40 - line_width, 5, 5 }
    )
end

function T.test_circle()
    cursor.x = 20
    cursor.y = 21
    cursor.width = 20
    cursor.height = 30

    draw_queue.by_cursor.circle({ 10, 11, 12, 13 }, 64, 0, "fill", 8)

    draw_queue.by_value.circle("fill", 30, 31, 10, { 10, 11, 12, 13 }, 8, 64)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "circ", "fill", 30, 31, 10, 64 })

    unittest.assert(cursor.height == 20)
end

function T.test_rotated_circle()
    cursor.x = 20
    cursor.y = 21
    cursor.width = 30
    cursor.height = 20

    draw_queue.by_cursor.circle({ 10, 11, 12, 13 }, 6, math.pi * 0.5, "line", 8)
    draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "circ", "line", 0, 0, 10, 6 })

    unittest.assert(cursor.width == 20)

    -- check that circle was draw with correct transformation
    -- stylua: ignore
    local t11, t12, t13, t14,
          t21, t22, t23, t24,
          t31, t32, t33, t34,
          t41, t42, t43, t44 = unpack(history.get(0))

    unittest.assert_almost_equals(t11, 0)
    unittest.assert_almost_equals(t12, -1)
    unittest.assert_almost_equals(t13, 0)
    unittest.assert_almost_equals(t14, 30)

    unittest.assert_almost_equals(t21, 1)
    unittest.assert_almost_equals(t22, 0)
    unittest.assert_almost_equals(t23, 0)
    unittest.assert_almost_equals(t24, 31)

    unittest.assert_almost_equals(t31, 0)
    unittest.assert_almost_equals(t32, 0)
    unittest.assert_almost_equals(t33, 1)
    unittest.assert_almost_equals(t34, 0)

    unittest.assert_almost_equals(t41, 0)
    unittest.assert_almost_equals(t42, 0)
    unittest.assert_almost_equals(t43, 0)
    unittest.assert_almost_equals(t44, 1)
end

function T.test_circle_outline()
    local line_width = 8
    local half_width = line_width * 0.5

    cursor.x = 20
    cursor.y = 21
    cursor.width = 20
    cursor.height = 20

    draw_queue.by_cursor.circle_outline({ 10, 11, 12, 13 }, line_width)
    draw()

    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "circ", "line", 30, 31, 10 - half_width })
end

function T.test_segmented_and_rotated_circle_outline()
    local line_width = 8
    local half_width = line_width * 0.5
    local radius = 10
    local segments = 3

    local function inradius_offset(r, n, o)
        return r + o / math.cos(math.pi / n)
    end

    cursor.x = 20
    cursor.y = 21
    cursor.width = 20
    cursor.height = 20

    draw_queue.by_cursor.circle_outline({ 10, 11, 12, 13 }, line_width, segments, math.pi * 0.5)
    draw()

    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(
        history.get(-1),
        { "circ", "line", 0, 0, inradius_offset(radius, segments, -half_width), segments }
    )

    -- check that circle was draw with correct transformation
    -- stylua: ignore
    local t11, t12, t13, t14,
          t21, t22, t23, t24,
          t31, t32, t33, t34,
          t41, t42, t43, t44 = unpack(history.get(0))

    unittest.assert_almost_equals(t11, 0)
    unittest.assert_almost_equals(t12, -1)
    unittest.assert_almost_equals(t13, 0)
    unittest.assert_almost_equals(t14, 30)

    unittest.assert_almost_equals(t21, 1)
    unittest.assert_almost_equals(t22, 0)
    unittest.assert_almost_equals(t23, 0)
    unittest.assert_almost_equals(t24, 31)

    unittest.assert_almost_equals(t31, 0)
    unittest.assert_almost_equals(t32, 0)
    unittest.assert_almost_equals(t33, 1)
    unittest.assert_almost_equals(t34, 0)

    unittest.assert_almost_equals(t41, 0)
    unittest.assert_almost_equals(t42, 0)
    unittest.assert_almost_equals(t43, 0)
    unittest.assert_almost_equals(t44, 1)
end

function T.test_hline()
    local line_width = 1
    local half_width = line_width / 2

    cursor.x = 0
    cursor.y = 0
    cursor.width = 20
    cursor.height = 20

    cursor.anchor_y = 0
    draw_queue.by_cursor.hline({ 10, 11, 12, 13 }, line_width)
    cursor.anchor_y = 0.5
    draw_queue.by_cursor.hline({ 234, 46, 57, 125 }, line_width)
    cursor.anchor_y = 1
    draw_queue.by_cursor.hline({ 26, 89, 124, 31 }, line_width)

    draw()

    unittest.assert_equal_lists(history.get(-3 - 8), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2 - 8), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1 - 8), { "line", 0, half_width, 20, half_width })
    unittest.assert_equal_lists(history.get(-3 - 4), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2 - 4), { "sc", 234, 46, 57, 125 })
    unittest.assert_equal_lists(history.get(-1 - 4), { "line", 0, 0, 20, 0 })
    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 26, 89, 124, 31 })
    unittest.assert_equal_lists(history.get(-1), { "line", 0, -half_width, 20, -half_width })
end

function T.test_vline()
    local line_width = 1
    local half_width = line_width / 2

    cursor.x = 0
    cursor.y = 0
    cursor.width = 20
    cursor.height = 20

    cursor.anchor_x = 0
    draw_queue.by_cursor.vline({ 10, 11, 12, 13 }, line_width)
    cursor.anchor_x = 0.5
    draw_queue.by_cursor.vline({ 234, 46, 57, 125 }, line_width)
    cursor.anchor_x = 1
    draw_queue.by_cursor.vline({ 26, 89, 124, 31 }, line_width)

    draw()

    unittest.assert_equal_lists(history.get(-3 - 8), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2 - 8), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1 - 8), { "line", half_width, 0, half_width, 20 })
    unittest.assert_equal_lists(history.get(-3 - 4), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2 - 4), { "sc", 234, 46, 57, 125 })
    unittest.assert_equal_lists(history.get(-1 - 4), { "line", 0, 0, 0, 20 })
    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 26, 89, 124, 31 })
    unittest.assert_equal_lists(history.get(-1), { "line", -half_width, 0, -half_width, 20 })
end

return T
