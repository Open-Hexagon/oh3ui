local knav = require("ui.control.keyboard_navigation")
local backend = require("ui.control.backend")
local wmode = knav.wrapping_mode
local events = require("ui.events")
local layer_backend = require("ui.layer.backend")
local unittest = require("tests.unittest")

local common = require("tests.unit.control.keyboard_navigation.common")

local T = {}

function T.set_up()
    --[[
        Grid setup:
        1 2 3
        4 5 6
        7 8 9
    ]]

    layer_backend.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)

    knav.make_cell()
    knav.grid_cell(2, 1)

    knav.make_cell()
    knav.grid_cell(3, 1)

    knav.make_cell()
    knav.grid_cell(1, 2)

    knav.make_cell()
    knav.grid_cell(2, 2)

    knav.make_cell()
    knav.grid_cell(3, 2)

    knav.make_cell()
    knav.grid_cell(1, 3)

    knav.make_cell()
    knav.grid_cell(2, 3)

    knav.make_cell()
    knav.grid_cell(3, 3)

    layer_backend.current_layer_is_active = false
end

function T.tear_down()
    common.reset_all()
end

function T.test_initial_move()
    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 1)
    backend.keyboard_navigation_deselect()
    events.clear()

    events.add("keypressed", "down")
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 1)
    backend.keyboard_navigation_deselect()
    events.clear()

    events.add("keypressed", "left")
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 9)
    backend.keyboard_navigation_deselect()
    events.clear()

    events.add("keypressed", "up")
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 9)
    backend.keyboard_navigation_deselect()
    events.clear()
end

function T.test_barriers_h()
    backend.keyboard_navigation_jump_to_cell(1)

    events.add("keypressed", "right")
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 2)

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 3)

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 3)

    events.clear()
    events.add("keypressed", "left")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 2)

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 1)

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 1)
end

function T.test_barriers_v()
    backend.keyboard_navigation_jump_to_cell(3)

    events.add("keypressed", "down")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 6)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 9)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 9)

    events.clear()
    events.add("keypressed", "up")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 6)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 3)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 3)
end

function T.test_wrapping_v()
    knav.set_wrapping(wmode.vertical)
    backend.keyboard_navigation_jump_to_cell(5)

    events.add("keypressed", "down")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 8)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 2)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 5)

    events.clear()
    events.add("keypressed", "up")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 2)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 8)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 5)
end

function T.test_wrapping_h()
    knav.set_wrapping(wmode.horizontal)
    backend.keyboard_navigation_jump_to_cell(5)

    events.add("keypressed", "left")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 4)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 6)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 5)

    events.clear()
    events.add("keypressed", "right")

    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 6)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 4)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 5)
end

function T.test_tab_wrapping()
    knav.set_wrapping(wmode.tab)

    events.add("keypressed", "right")

    backend.keyboard_navigation_jump_to_cell(3)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 4)

    backend.keyboard_navigation_jump_to_cell(9)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 1)

    events.clear()
    events.add("keypressed", "left")

    backend.keyboard_navigation_jump_to_cell(4)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 3)

    backend.keyboard_navigation_jump_to_cell(1)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 9)
end

function T.test_page_wrapping()
    knav.set_wrapping(wmode.page)
    knav.set_page_length(3)

    events.add("keypressed", "right")

    backend.keyboard_navigation_jump_to_cell(3)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 6)

    backend.keyboard_navigation_jump_to_cell(9)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 9)

    events.clear()
    events.add("keypressed", "left")

    backend.keyboard_navigation_jump_to_cell(7)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 4)

    backend.keyboard_navigation_jump_to_cell(1)
    backend.keyboard_navigation_evaluate()

    unittest.assert(knav.get_selected_cell_id() == 1)
end

return T
