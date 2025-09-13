local upvalue = require("tests.upvalue")
local knav = require("ui.control.keyboard_navigation")
local wmode = knav.wrapping_mode
local enable_intersection_checks = require("ui.control.mouse_navigation.sensor").enable_intersection_checks
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")
local monkeypatch = require("tests.monkeypatch")

local T = {}

local mouse_is_visible

function T.set_up_case()
    love.mouse.setVisible = monkeypatch.replace(love.mouse.setVisible, function(a)
        mouse_is_visible = a
    end)
end

function T.tear_down_case()
    love.mouse.setVisible = monkeypatch.get_original(love.mouse.setVisible)
end

function T.set_up()
    knav.set_wrapping()
end

function T.tear_down()
    enable_intersection_checks()
    knav.reset()
    events.clear()
end

function T.test_mouse_hiding()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    control_data.current_layer_is_active = false

    mouse_is_visible = nil
    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(mouse_is_visible == false)
    unittest.assert(upvalue.get_by_name(enable_intersection_checks, "do_intersections") == false)
end

return T
