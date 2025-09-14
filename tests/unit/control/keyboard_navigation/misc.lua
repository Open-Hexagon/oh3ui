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
    knav.set_page_length(1)
end

local function get_selected_cell_id()
    return upvalue.get_by_name(knav.deselect, "selected_cell_id", "grid_x", "grid_y")
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

function T.test_negative_page_length()
    unittest.assert_error(knav.set_page_length, nil, 0)
end

function T.test_inactive()
    control_data.current_layer_is_active = false

    unittest.assert(knav.make_cell() == 0)
    unittest.assert(control_data.current_cell_id == 0)
    knav.grid_cell(1, 1)
    unittest.assert(upvalue.get_by_name(knav.grid_cell, "last_gridded_cell_id") == nil)
end

function T.test_too_far()
    knav.set_wrapping(wmode.horizontal)
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(300, 1)

    control_data.current_layer_is_active = false

    events.add("keypressed", "right")

    knav.jump_to_cell(1)
    unittest.assert_error(knav.evaluate)

    knav.jump_to_cell(2)
    unittest.assert_error(knav.evaluate)

    knav.set_wrapping()
end

function T.test_bad_grid_fill()
    unittest.assert_error(knav.fill_grid, nil, -1, 0, 1, 1, 1)
    unittest.assert_error(knav.fill_grid, nil, -1, 1, 0, 1, 1)
    unittest.assert_error(knav.fill_grid, nil, -1, 1, 1, 0, 1)
    unittest.assert_error(knav.fill_grid, nil, -1, 1, 1, 1, 0)
end

function T.test_bad_jump_to_cell()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(2, 1)

    control_data.current_layer_is_active = false

    unittest.assert_error(knav.jump_to_cell, nil, -1)
    unittest.assert_error(knav.jump_to_cell, nil, 3)
end

function T.test_jump_to_cell()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(3, 6)

    knav.make_cell()
    knav.grid_cell(5, 4)

    control_data.current_layer_is_active = false

    local id, x, y

    knav.jump_to_cell(1)
    id, x, y = get_selected_cell_id()
    unittest.assert(id == 1)
    unittest.assert(x == 3)
    unittest.assert(y == 6)

    knav.jump_to_cell(2)
    id, x, y = get_selected_cell_id()
    unittest.assert(id == 2)
    unittest.assert(x == 5)
    unittest.assert(y == 4)

    knav.jump_to_cell(0)
    id, x, y = get_selected_cell_id()
    unittest.assert(id == 0)
    unittest.assert(x == nil)
    unittest.assert(y == nil)
end

return T
