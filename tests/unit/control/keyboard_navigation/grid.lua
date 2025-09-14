local upvalue = require("tests.upvalue")
local knav = require("ui.control.keyboard_navigation")
local wmode = knav.wrapping_mode
local enable_intersection_checks = require("ui.control.mouse_navigation.sensor").enable_intersection_checks
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")

local T = {}

function T.set_up_case()
    --[[
        Grid setup:
        1 2 3
        4 5 6
        7 8 9
    ]]

    control_data.current_layer_is_active = true

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

    control_data.current_layer_is_active = false
end

function T.tear_down_case()
    knav.reset()
    enable_intersection_checks()
end

function T.set_up()
    knav.set_wrapping()
end

function T.tear_down()
    knav.deselect()
    events.clear()
    knav.set_page_length(1)
end

local function get_selected_cell_id()
    return upvalue.get_by_name(knav.deselect, "selected_cell_id")
end

function T.test_initial_move()
    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 1)
    knav.deselect()
    events.clear()

    events.add("keypressed", "down")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 1)
    knav.deselect()
    events.clear()

    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 9)
    knav.deselect()
    events.clear()

    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 9)
    knav.deselect()
    events.clear()
end

function T.test_barriers_h()
    knav.jump_to_cell(1)

    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 2)

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 3)

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 3)

    events.clear()
    events.add("keypressed", "left")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 2)

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 1)

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 1)
end

function T.test_barriers_v()
    knav.jump_to_cell(3)

    events.add("keypressed", "down")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 6)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 9)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 9)

    events.clear()
    events.add("keypressed", "up")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 6)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 3)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 3)
end

function T.test_wrapping_v()
    knav.set_wrapping(wmode.vertical)
    knav.jump_to_cell(5)

    events.add("keypressed", "down")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 8)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 2)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 5)

    events.clear()
    events.add("keypressed", "up")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 2)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 8)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 5)
end

function T.test_wrapping_h()
    knav.set_wrapping(wmode.horizontal)
    knav.jump_to_cell(5)

    events.add("keypressed", "left")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 4)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 6)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 5)

    events.clear()
    events.add("keypressed", "right")

    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 6)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 4)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 5)
end

function T.test_tab_wrapping()
    knav.set_wrapping(wmode.tab)

    events.add("keypressed", "right")

    knav.jump_to_cell(3)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 4)

    knav.jump_to_cell(9)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 1)

    events.clear()
    events.add("keypressed", "left")

    knav.jump_to_cell(4)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 3)

    knav.jump_to_cell(1)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 9)
end

function T.test_page_wrapping()
    knav.set_wrapping(wmode.page)
    knav.set_page_length(3)

    events.add("keypressed", "right")

    knav.jump_to_cell(3)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 6)

    knav.jump_to_cell(9)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 9)

    events.clear()
    events.add("keypressed", "left")

    knav.jump_to_cell(7)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 4)

    knav.jump_to_cell(1)
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 1)
end

return T
