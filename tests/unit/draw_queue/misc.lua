local scissor_stack = require("ui.draw_queue.scissor_stack")
local sensor = require("ui.control.sensor")
local history = require("tests.history")
local monkeypatch = require("tests.monkeypatch")
local te = require("tests.transform_emulator")
local draw_data = require("ui.draw_queue.draw_data")
local cursor = require("ui.cursor")
local unittest = require("tests.unittest")
local draw_queue = require("ui.draw_queue")
local draw = require("ui.draw_queue.draw")
local op_ids = require("ui.draw_queue.draw_operation")

local T = {}

function T.set_up_case()
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
    sensor.push = history.patch(sensor.push, "sp")
end

function T.set_up()
    love.graphics.origin()
    history.clear()
    draw_data.clear()
    cursor.reset()
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
    sensor.push = history.get_original(sensor.push)

    love.graphics.origin()
    history.clear()
    draw_data.clear()
    cursor.reset()
end

function T.test_pop_mask()
    draw_queue.pop_mask()
    draw()
    unittest.assert_equal_lists(history.get(0), { "sspop" })
end

function T.test_mouse_sensor_no_scissor()
    love.graphics.scale(2)

    draw_data.add_draw_operation(op_ids.mouse_sensor, draw_data.make_placement(10, 10, 20, 20), 7, 3)
    draw()
    unittest.assert_equal_lists(history.get(0), { "sp", 7, 3, 20, 20, 40, 40 })
end

function T.test_mouse_sensor_with_scissor()
    love.graphics.setScissor(10, 10, 20, 20)

    draw_data.add_draw_operation(op_ids.mouse_sensor, draw_data.make_placement(0, 0, 20, 20), 3, 6)
    draw()
    unittest.assert_equal_lists(history.get(0), { "sp", 3, 6, 10, 10, 20, 20 })

    love.graphics.setScissor()
end

function T.test_mouse_sensor_with_no_intersect_scissor()
    love.graphics.setScissor(0, 0, 5, 5)

    local l = history.get_length()
    draw_data.add_draw_operation(op_ids.mouse_sensor, draw_data.make_placement(10, 10, 20, 20), 7, 3)
    draw()
    unittest.assert(history.get_length() == l)

    love.graphics.setScissor()
end

return T
