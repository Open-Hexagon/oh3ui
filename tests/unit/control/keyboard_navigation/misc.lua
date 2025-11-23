local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local wmode = knav.wrapping_mode
local events = require("ui.events")
local sensor = require("ui.control.sensor")
local common = require("tests.unit.control.keyboard_navigation.common")
local layer_backend = require("ui.layer.backend")
local unittest = require("tests.unittest")
local monkeypatch = require("tests.monkeypatch")
local backend = require("ui.control.backend")

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
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    layer_backend.current_layer_is_active = false

    mouse_is_visible = nil
    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()
    unittest.assert(mouse_is_visible == false)
    unittest.assert(sensor.do_intersections == false)
end

function T.test_negative_page_length()
    unittest.assert_error(knav.set_page_length, nil, 0)
end

function T.test_inactive()
    layer_backend.current_layer_is_active = false

    unittest.assert(knav.make_cell() == 0)
    unittest.assert(knav.get_current_cell_id() == 0)
    knav.grid_cell(1, 1)
    unittest.assert(knav.get_last_gridded_cell_id() == nil)
end

function T.test_too_far()
    knav.set_wrapping(wmode.horizontal)
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(300, 1)

    layer_backend.current_layer_is_active = false

    events.add("keypressed", "right")

    backend.keyboard_navigation_jump_to_cell(1)
    unittest.assert_error(knav.evaluate)

    backend.keyboard_navigation_jump_to_cell(2)
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
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(2, 1)

    layer_backend.current_layer_is_active = false

    unittest.assert_error(backend.keyboard_navigation_jump_to_cell, nil, -1)
    unittest.assert_error(backend.keyboard_navigation_jump_to_cell, nil, 3)
end

function T.test_jump_to_cell()
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(3, 6)

    knav.make_cell()
    knav.grid_cell(5, 4)

    layer_backend.current_layer_is_active = false

    backend.keyboard_navigation_jump_to_cell(1)
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 1)
    unittest.assert(x == 3)
    unittest.assert(y == 6)

    backend.keyboard_navigation_jump_to_cell(2)
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 2)
    unittest.assert(x == 5)
    unittest.assert(y == 4)

    backend.keyboard_navigation_jump_to_cell(0)
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 0)
    unittest.assert(x == nil)
    unittest.assert(y == nil)
end

function T.test_wrapping_reencounter()
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(2, 1)

    knav.make_cell()
    knav.grid_cell(1, 2, 2, 1)

    layer_backend.current_layer_is_active = false

    knav.set_wrapping(wmode.horizontal)
    backend.keyboard_navigation_jump_to_cell(2)

    events.add("keypressed", "down")
    -- ! we are at grid position (2,2) in between these two events
    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()

    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
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

    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(5, 1, 2, 1)

    knav.make_cell()
    knav.grid_cell(8, 1)

    knav.fill_grid(knav.op_cell.wrap, 10, 1)

    layer_backend.current_layer_is_active = false

    events.add("keypressed", "right")

    knav.fill_grid(knav.op_cell.barrier, 3, 1)
    backend.keyboard_navigation_jump_to_cell(2)
    backend.keyboard_navigation_evaluate()
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)

    knav.fill_grid(knav.op_cell.page, 3, 1)
    backend.keyboard_navigation_jump_to_cell(2)
    backend.keyboard_navigation_evaluate()
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)

    knav.fill_grid(knav.op_cell.redirect, 3, 1)
    backend.keyboard_navigation_jump_to_cell(2)
    backend.keyboard_navigation_evaluate()
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)

    knav.fill_grid(knav.op_cell.tab, 3, 1)
    backend.keyboard_navigation_jump_to_cell(2)
    backend.keyboard_navigation_evaluate()
    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 1)
    unittest.assert(x == 5)
    unittest.assert(y == 1)
end

function T.test_evaluate_with_no_cells_or_events()
    knav.selection_has_changed = true
    upvalue.set_by_name(knav.evaluate_without_events, "last_action", kba.activate)
    upvalue.set_by_name(knav.evaluate_without_events, "last_is_repeat", true)
    upvalue.set_by_name(knav.evaluate_without_events, "held_action", kba.activate)

    backend.keyboard_navigation_evaluate()

    local a, b, c = upvalue.get_by_name(knav.evaluate_without_events, "last_action", "last_is_repeat", "held_action")

    unittest.assert(a == nil)
    unittest.assert(b == false)
    unittest.assert(c == nil)
end

function T.test_invalid_grid_position()
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(4, 2)

    layer_backend.current_layer_is_active = false

    backend.keyboard_navigation_jump_to_cell(1)

    knav.set_grid_location(-1, -1)

    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()

    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 1)
    unittest.assert(x == 4)
    unittest.assert(y == 2)
end

function T.test_selection_has_changed()
    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)
    knav.make_cell()
    knav.grid_cell(2, 1)

    layer_backend.current_layer_is_active = false

    backend.keyboard_navigation_selection_has_changed = false

    backend.keyboard_navigation_jump_to_cell(1)

    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()
    events.clear()

    unittest.assert(backend.keyboard_navigation_selection_has_changed == true)

    backend.keyboard_navigation_evaluate()

    unittest.assert(backend.keyboard_navigation_selection_has_changed == false)
end

return T
