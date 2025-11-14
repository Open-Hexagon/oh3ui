local unittest = require("tests.unittest")
local draw_queue = require("ui.draw_queue")
local scissor_stack = require("ui.draw_queue.scissor_stack")
local sensor = require("ui.control.sensor")
local history = require("tests.history")
local monkeypatch = require("tests.monkeypatch")
local te = require("tests.transform_emulator")

local T = {}

function T.set_up_case()
    unittest.skip("needs redo after major changes")
    unittest.skip_if(os.getenv("HEADLESS"), "this test cannot be run in headless mode")

    -- patch functions to intercept arguments

    love.graphics.setLineWidth = history.patch(love.graphics.setLineWidth, "lw")
    love.graphics.setColor = history.patch(love.graphics.setColor, "sc")

    love.graphics.rectangle = monkeypatch.replace(love.graphics.rectangle, function(...)
        history.add({ "rect", ... })
        history.add({ te.get_matrix() })
    end)
    love.graphics.circle = monkeypatch.replace(love.graphics.circle, function(...)
        history.add({ "circ", ... })
        history.add({ te.get_matrix() })
    end)
    love.graphics.line = monkeypatch.replace(love.graphics.line, function(...)
        history.add({ "line", ... })
        history.add({ te.get_matrix() })
    end)
    love.graphics.polygon = monkeypatch.replace(love.graphics.polygon, function(...)
        history.add({ "poly", ... })
        history.add({ te.get_matrix() })
    end)
    love.graphics.draw = monkeypatch.replace(love.graphics.draw, function(...)
        history.add({ "draw", ... })
        history.add({ te.get_matrix() })
    end)

    love.graphics.push = monkeypatch.add(love.graphics.push, te.push)
    love.graphics.origin = monkeypatch.add(love.graphics.origin, te.origin)
    love.graphics.translate = monkeypatch.add(love.graphics.translate, te.translate)
    love.graphics.rotate = monkeypatch.add(love.graphics.rotate, te.rotate)
    love.graphics.pop = monkeypatch.add(love.graphics.pop, te.pop)

    scissor_stack.pop = history.patch(scissor_stack.pop, "sspop")
    scissor_stack.push = history.patch(scissor_stack.push, "sspush")
    scissor_stack.revert = history.patch(scissor_stack.revert, "ssr")
    sensor.push = history.patch(sensor.push, "sp")
end

function T.tear_down_case()
    love.graphics.setLineWidth = history.get_original(love.graphics.setLineWidth)
    love.graphics.setColor = history.get_original(love.graphics.setColor)

    love.graphics.rectangle = monkeypatch.get_original(love.graphics.rectangle)
    love.graphics.circle = monkeypatch.get_original(love.graphics.circle)
    love.graphics.line = monkeypatch.get_original(love.graphics.line)
    love.graphics.polygon = monkeypatch.get_original(love.graphics.polygon)
    love.graphics.draw = monkeypatch.get_original(love.graphics.draw)

    love.graphics.push = monkeypatch.get_original(love.graphics.push)
    love.graphics.origin = monkeypatch.get_original(love.graphics.origin)
    love.graphics.translate = monkeypatch.get_original(love.graphics.translate)
    love.graphics.rotate = monkeypatch.get_original(love.graphics.rotate)
    love.graphics.pop = monkeypatch.get_original(love.graphics.pop)

    scissor_stack.pop = history.get_original(scissor_stack.pop)
    scissor_stack.push = history.get_original(scissor_stack.push)
    scissor_stack.revert = history.get_original(scissor_stack.revert)
    sensor.push = history.get_original(sensor.push)

    love.graphics.origin()
    history.clear()
end

function T.test_push_scissor()
    love.graphics.scale(2)

    draw_queue.push_scissor(10, 10, 30, 30)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(0), { "sspush", 20, 20, 40, 40 })

    love.graphics.origin()
end

function T.test_pop_scissor()
    draw_queue.pop_scissor()
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(0), { "sspop" })
end

function T.test_revert_scissor()
    draw_queue.revert_scissor(55)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(0), { "ssr", 55 })
end

function T.test_mouse_sensor_no_scissor()
    love.graphics.scale(2)

    draw_queue.mouse_sensor(7, 3, 10, 10, 20, 20)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(0), { "sp", 7, 3, 20, 20, 40, 40 })

    love.graphics.origin()
end

function T.test_mouse_sensor_with_scissor()
    love.graphics.setScissor(10, 10, 20, 20)

    draw_queue.mouse_sensor(3, 6, 0, 0, 20, 20)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(0), { "sp", 3, 6, 10, 10, 20, 20 })

    love.graphics.setScissor()
end

function T.test_mouse_sensor_with_no_intersect_scissor()
    love.graphics.setScissor(0, 0, 5, 5)

    local l = history.get_length()
    draw_queue.mouse_sensor(3, 6, 10, 10, 20, 20)
    draw_queue.draw()
    unittest.assert(history.get_length() == l)

    love.graphics.setScissor()
end

function T.test_rectangle()
    draw_queue.rectangle("fill", 30, 31, 40, 41, { 10, 11, 12, 13 }, 2, 4, 3)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 3 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "rect", "fill", 30, 31, 10, 10, 2, 4 })
end

function T.test_rectangle_outline()
    local line_width = 8
    local half_width = line_width * 0.5
    draw_queue.rectangle_outline(30, 31, 60, 61, { 10, 11, 12, 13 }, line_width, 3, 2)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(
        history.get(-1),
        { "rect", "line", 30 + half_width, 31 + half_width, 30 - line_width, 30 - line_width, 3, 2 }
    )
end

function T.test_circle()
    draw_queue.circle("fill", 30, 31, 70, { 10, 11, 12, 13 }, 8, 64)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "circ", "fill", 30, 31, 70, 64 })
end

function T.test_rotated_circle()
    draw_queue.circle("line", 30, 31, 70, { 10, 11, 12, 13 }, 8, 6, math.pi * 0.5)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 8 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "circ", "line", 0, 0, 70, 6 })

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
    draw_queue.circle_outline(30, 31, 70, line_width, { 10, 11, 12, 13 })
    draw_queue.draw()

    unittest.assert_equal_lists(history.get(-3), { "lw", line_width })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "circ", "line", 30, 31, 70 - half_width })
end

function T.test_segmented_and_rotated_circle_outline()
    local line_width = 8
    local half_width = line_width * 0.5
    local radius = 70
    local segments = 3

    local function inradius_offset(r, n, o)
        return r + o / math.cos(math.pi / n)
    end

    draw_queue.circle_outline(30, 31, radius, line_width, { 10, 11, 12, 13 }, segments, math.pi * 0.5)
    draw_queue.draw()

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

function T.test_polygon()
    draw_queue.polygon("line", { 10, 11, 12, 13 }, 1, 0, 0, 10, 0, 10, 20)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 1 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "poly", "line", 0, 0, 10, 0, 10, 20 })
end

function T.test_text()
    local t = {}

    love.graphics.scale(2)
    draw_queue.text(t, 30, 30, { 10, 11, 12, 13 })
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "draw", t, 60, 60 })
    -- stylua: ignore
    unittest.assert_equal_lists(history.get(0), {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
    })

    love.graphics.origin()
end

function T.test_line()
    draw_queue.line(1, { 10, 11, 12, 13 }, 0, 0, 10, 0, 10, 20)
    draw_queue.draw()
    unittest.assert_equal_lists(history.get(-3), { "lw", 1 })
    unittest.assert_equal_lists(history.get(-2), { "sc", 10, 11, 12, 13 })
    unittest.assert_equal_lists(history.get(-1), { "line", 0, 0, 10, 0, 10, 20 })
end

function T.test_reserve()
    unittest.assert_error(draw_queue.take_reservation, nil, 0)

    unittest.assert_error(draw_queue.reserve, nil, -1)

    local r = draw_queue.reserve(3)

    draw_queue.revert_scissor(1)

    draw_queue.take_reservation(r)
    draw_queue.revert_scissor(2)
    draw_queue.take_reservation(r)
    draw_queue.revert_scissor(3)
    draw_queue.take_reservation(r)
    draw_queue.revert_scissor(4)

    draw_queue.take_reservation(r)
    unittest.assert_error(draw_queue.revert_scissor, nil, 5)

    draw_queue.draw()

    unittest.assert_equal_lists(history.get(-3), { "ssr", 2 })
    unittest.assert_equal_lists(history.get(-2), { "ssr", 3 })
    unittest.assert_equal_lists(history.get(-1), { "ssr", 4 })
    unittest.assert_equal_lists(history.get(0), { "ssr", 1 })
end

function T.test_reserve_gap()
    local r = draw_queue.reserve(1)

    unittest.assert_error(draw_queue.draw)

    -- clean up before finishing test
    draw_queue.take_reservation(r)
    draw_queue.nop()

    draw_queue.draw()
end

return T
