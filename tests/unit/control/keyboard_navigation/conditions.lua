local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local wmode = knav.wrapping_mode
local events = require("ui.events")
local layer_backend = require("ui.layer.backend")
local unittest = require("tests.unittest")
local backend = require("ui.control.backend")

local common = require("tests.unit.control.keyboard_navigation.common")

local T = {}

local id, x, y

function T.set_up()
    --[[
        grid setup:
        -4 | -4  | -4
        -4 |  1  | -4
        -4 | -4  | -4
        -4 |  2  | -4
        -4 |  3  | -4
    ]]

    layer_backend.current_layer_is_active = true

    knav.fill_grid(knav.op_cell.redirect, 1, 1)

    knav.make_cell()
    knav.grid_cell(1, 2)

    knav.fill_grid(knav.op_cell.redirect, 1, 3)

    knav.make_cell("default")
    knav.grid_cell(1, 4)

    knav.make_cell("escape")
    knav.grid_cell(1, 5)

    layer_backend.current_layer_is_active = false

    knav.set_wrapping(wmode.redirect)
end

function T.tear_down()
    common.reset_all()
end

function T.test_change_to_bad_cell()
    unittest.assert_error(knav.set_current_cell_id, nil, -1)
end

function T.test_is_selected()
    knav.set_current_cell_id(0)
    unittest.assert(not knav.is_selected(0))

    backend.keyboard_navigation_jump_to_cell(2)
    knav.set_current_cell_id(2)
    unittest.assert(knav.is_selected())

    unittest.assert(not knav.is_selected(1))

    unittest.assert_error(knav.is_selected, nil, -1)
end

function T.test_default()
    events.add("keypressed", "return")
    backend.keyboard_navigation_evaluate()

    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 2)
    unittest.assert(x == 1)
    unittest.assert(y == 4)

    knav.set_current_cell_id(2)
    unittest.assert(knav.get_action() == kba.activate)
end

function T.test_escape()
    events.add("keypressed", "escape")
    backend.keyboard_navigation_evaluate()

    id = knav.get_selected_cell_id()
    x, y = knav.get_grid_location()
    unittest.assert(id == 3)
    unittest.assert(x == 1)
    unittest.assert(y == 5)

    knav.set_current_cell_id(3)
    unittest.assert(knav.get_action() == kba.activate)
end

function T.test_get_action_and_redirection()
    backend.keyboard_navigation_jump_to_cell(1)
    events.add("keypressed", "space")
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_action(2) == nil)
    unittest.assert(knav.get_action(1) == kba.activate)

    events.clear()
    backend.keyboard_navigation_evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)

    events.add("keypressed", "up")
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.up)
    events.clear()
    events.add("keypressed", "down")
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.down)
    events.clear()
    events.add("keypressed", "left")
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.left)
    events.clear()
    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.right)
    events.clear()

    backend.keyboard_navigation_evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)
end

function T.test_repeated_get_action_and_redirection()
    backend.keyboard_navigation_jump_to_cell(1)

    events.add("keypressed", "up", nil, true)
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.up)
    events.clear()

    backend.keyboard_navigation_evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)

    events.add("keypressed", "down", nil, true)
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.down)
    events.clear()
    events.add("keypressed", "left", nil, true)
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.left)
    events.clear()
    events.add("keypressed", "right", nil, true)
    backend.keyboard_navigation_evaluate()
    unittest.assert(knav.get_action(1) == kba.right)
    events.clear()

    backend.keyboard_navigation_evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)
end

function T.test_escape_and_return_not_repeatable()
    backend.keyboard_navigation_jump_to_cell(1)

    events.add("keypressed", "space", nil, true)
    backend.keyboard_navigation_evaluate()
    events.clear()

    unittest.assert(knav.get_action(1) == nil)

    events.add("keypressed", "escape", nil, true)
    backend.keyboard_navigation_evaluate()
    events.clear()

    unittest.assert(knav.get_action(1) == nil)
end

function T.test_get_holding()
    backend.keyboard_navigation_jump_to_cell(1)

    unittest.assert(knav.get_holding(2) == nil)
    unittest.assert(knav.get_holding(1) == nil)

    events.add("keypressed", "up")
    backend.keyboard_navigation_evaluate()
    events.clear()

    unittest.assert(knav.get_holding(1) == kba.up)

    -- ! this sequence will never actually occur but it's just used to clear the held_action
    events.add("keyreleased", "up")
    backend.keyboard_navigation_evaluate()
    events.clear()

    unittest.assert(knav.get_holding(1) == nil)

    events.add("keypressed", "up", nil, true)
    backend.keyboard_navigation_evaluate()
    events.clear()

    unittest.assert(knav.get_holding(1) == nil)
end

return T
