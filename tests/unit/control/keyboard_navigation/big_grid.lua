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
        1 0 0 2 3
        0 0 0 0 0
        4 0 0 5 5
        6 0 0 5 5
    ]]

    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1)
    knav.make_cell()
    knav.grid_cell(4, 1)
    knav.make_cell()
    knav.grid_cell(5, 1)

    knav.make_cell()
    knav.grid_cell(1, 3)

    knav.make_cell()
    knav.grid_cell(4, 3, 2, 2)

    knav.make_cell()
    knav.grid_cell(1, 4)

    control_data.current_layer_is_active = false
end

function T.tear_down_case()
    knav.reset()
    enable_intersection_checks()
end

function T.tear_down()
    enable_intersection_checks()
    knav.deselect()
    events.clear()
    knav.set_page_length(1)
end

local function get_selected_cell_id()
    return upvalue.get_by_name(knav.deselect, "selected_cell_id")
end

function T.test_6ru()
    knav.jump_to_cell(6)
    events.add("keypressed", "right")
    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 2)
end

function T.test_6rru()
    knav.jump_to_cell(6)
    events.add("keypressed", "right")
    events.add("keypressed", "right")
    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 3)
end

function T.test_3dl()
    knav.jump_to_cell(3)
    events.add("keypressed", "down")
    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 4)
end

function T.test_3ddl()
    knav.jump_to_cell(3)
    events.add("keypressed", "down")
    events.add("keypressed", "down")
    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(get_selected_cell_id() == 6)
end

return T
