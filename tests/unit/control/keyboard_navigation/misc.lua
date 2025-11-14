local upvalue = require("tests.upvalue")
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local wmode = knav.wrapping_mode
local events = require("ui.events")
local enable_intersection_checks = require("ui.control.sensor").enable_intersection_checks
local common = require("tests.unit.control.keyboard_navigation.common")
local shared_data = require("ui.stack_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")
local monkeypatch = require("tests.monkeypatch")

local T = {}

local mouse_is_visible
local id, x, y

function T.set_up_case()
    love.mouse.setVisible = monkeypatch.replace(love.mouse.setVisible, function(a)
        mouse_is_visible = a
    end)
end

function T.tear_down_case()
    love.mouse.setVisible = monkeypatch.get_original(love.mouse.setVisible)
end

function T.tear_down()
    common.reset_all()
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

    knav.jump_to_cell(1)
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == 3)
    unittest.assert(y == 6)

    knav.jump_to_cell(2)
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 2)
    unittest.assert(x == 5)
    unittest.assert(y == 4)

    knav.jump_to_cell(0)
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 0)
    unittest.assert(x == nil)
    unittest.assert(y == nil)
end

function T.test_wrapping_reencounter()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(2, 1)

    knav.make_cell()
    knav.grid_cell(1, 2, 2, 1)

    control_data.current_layer_is_active = false

    knav.set_wrapping(wmode.horizontal)
    knav.jump_to_cell(2)

    events.add("keypressed", "down")
    -- ! we are at grid position (2,2) in between these two events
    events.add("keypressed", "right")
    knav.evaluate()

    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 3)
    -- ! reencountering the same cell when wrapping doesn't actually move the grid position
    unittest.assert(x == 2)
    unittest.assert(y == 2)
end

function T.test_wrapping_points()
    --[[
    grid setup:
    X changes throughout the test
    ... -1 | 0 0 X 0 1 1 0 2 0 -2 | -1 ...
    ]]

    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(5, 1, 2, 1)

    knav.make_cell()
    knav.grid_cell(8, 1)

    knav.fill_grid(knav.op_cell.wrap, 10, 1)

    control_data.current_layer_is_active = false

    events.add("keypressed", "right")

    knav.fill_grid(knav.op_cell.barrier, 3, 1)
    knav.jump_to_cell(2)
    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)

    knav.fill_grid(knav.op_cell.page, 3, 1)
    knav.jump_to_cell(2)
    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)

    knav.fill_grid(knav.op_cell.redirect, 3, 1)
    knav.jump_to_cell(2)
    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)

    knav.fill_grid(knav.op_cell.tab, 3, 1)
    knav.jump_to_cell(2)
    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)
end

function T.test_evaluate_with_no_cells_or_events()
    knav.selection_has_changed = true
    upvalue.set_by_name(knav.evaluate_without_events, "last_action", kba.activate)
    upvalue.set_by_name(knav.evaluate_without_events, "last_is_repeat", true)
    upvalue.set_by_name(knav.evaluate_without_events, "held_action", kba.activate)

    knav.evaluate()

    local a, b, c = upvalue.get_by_name(knav.evaluate_without_events, "last_action", "last_is_repeat", "held_action")

    unittest.assert(a == nil)
    unittest.assert(b == false)
    unittest.assert(c == nil)
end

function T.test_invalid_grid_position()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(4, 2)

    control_data.current_layer_is_active = false

    knav.jump_to_cell(1)

    upvalue.set_by_name(knav.deselect, "grid_x", -1)
    upvalue.set_by_name(knav.deselect, "grid_y", -1)

    events.add("keypressed", "right")
    knav.evaluate()

    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == 4)
    unittest.assert(y == 2)
end

function T.test_selection_has_changed()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)
    knav.make_cell()
    knav.grid_cell(2, 1)

    control_data.current_layer_is_active = false

    knav.selection_has_changed = false

    knav.jump_to_cell(1)

    events.add("keypressed", "right")
    knav.evaluate()
    events.clear()

    unittest.assert(knav.selection_has_changed == true)

    knav.evaluate()

    unittest.assert(knav.selection_has_changed == false)
end

return T
