local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local wmode = knav.wrapping_mode
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")

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

    control_data.current_layer_is_active = true

    knav.fill_grid(knav.op_cell.redirect, 1, 1)

    knav.make_cell()
    knav.grid_cell(1, 2)

    knav.fill_grid(knav.op_cell.redirect, 1, 3)

    knav.make_cell("default")
    knav.grid_cell(1, 4)

    knav.make_cell("escape")
    knav.grid_cell(1, 5)

    control_data.current_layer_is_active = false

    knav.set_wrapping(wmode.redirect)
end

function T.tear_down()
    common.reset_all()
end

function T.test_change_to_bad_cell()
    unittest.assert_error(knav.change_current_cell, nil, -1)
end

function T.test_is_selected()
    knav.change_current_cell(0)
    unittest.assert(not knav.is_selected(0))

    knav.jump_to_cell(2)
    knav.change_current_cell(2)
    unittest.assert(knav.is_selected())

    unittest.assert(not knav.is_selected(1))

    unittest.assert_error(knav.is_selected, nil, -1)
end

function T.test_default()
    events.add("keypressed", "return")
    knav.evaluate()

    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 2)
    unittest.assert(x == 1)
    unittest.assert(y == 4)

    knav.change_current_cell(2)
    unittest.assert(knav.get_action() == kba.activate)
end

function T.test_escape()
    events.add("keypressed", "escape")
    knav.evaluate()

    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 3)
    unittest.assert(x == 1)
    unittest.assert(y == 5)

    knav.change_current_cell(3)
    unittest.assert(knav.get_action() == kba.activate)
end

function T.test_get_action_and_redirection()
    knav.jump_to_cell(1)
    events.add("keypressed", "space")
    knav.evaluate()

    unittest.assert(knav.get_action(2) == nil)
    unittest.assert(knav.get_action(1) == kba.activate)

    events.clear()
    knav.evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)

    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.up)
    events.clear()
    events.add("keypressed", "down")
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.down)
    events.clear()
    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.left)
    events.clear()
    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.right)
    events.clear()

    knav.evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)
end

function T.test_repeated_get_action_and_redirection()
    knav.jump_to_cell(1)

    events.add("keypressed", "up", nil, true)
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.up)
    events.clear()

    knav.evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)

    events.add("keypressed", "down", nil, true)
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.down)
    events.clear()
    events.add("keypressed", "left", nil, true)
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.left)
    events.clear()
    events.add("keypressed", "right", nil, true)
    knav.evaluate()
    unittest.assert(knav.get_action(1) == kba.right)
    events.clear()

    knav.evaluate()
    -- ! action must be reasserted every frame
    unittest.assert(knav.get_action(1) == nil)
end

function T.test_escape_and_return_not_repeatable()
    knav.jump_to_cell(1)

    events.add("keypressed", "space", nil, true)
    knav.evaluate()
    events.clear()

    unittest.assert(knav.get_action(1) == nil)

    events.add("keypressed", "escape", nil, true)
    knav.evaluate()
    events.clear()

    unittest.assert(knav.get_action(1) == nil)
end

function T.test_get_holding()
    knav.jump_to_cell(1)

    -- ! this clears any junk that's in the held_action variable
    knav.evaluate_without_events()

    unittest.assert(knav.get_holding(2) == nil)
    unittest.assert(knav.get_holding(1) == nil)

    events.add("keypressed", "up")
    knav.evaluate()
    events.clear()

    unittest.assert(knav.get_holding(1) == kba.up)

    -- ! this sequence will never actually occur but it's just used to clear the held_action
    events.add("keyreleased", "up")
    knav.evaluate()
    events.clear()

    unittest.assert(knav.get_holding(1) == nil)

    events.add("keypressed", "up", nil, true)
    knav.evaluate()
    events.clear()

    unittest.assert(knav.get_holding(1) == nil)
end

return T
