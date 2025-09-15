local knav = require("ui.control.keyboard_navigation")
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")

local common = require("tests.unit.control.keyboard_navigation.common")

local T = {}

function T.set_up()
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

function T.tear_down()
    common.reset_all()
end

function T.test_6ru()
    knav.jump_to_cell(6)
    events.add("keypressed", "right")
    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 2)
end

function T.test_6rru()
    knav.jump_to_cell(6)
    events.add("keypressed", "right")
    events.add("keypressed", "right")
    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 3)
end

function T.test_3dl()
    knav.jump_to_cell(3)
    events.add("keypressed", "down")
    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 4)
end

function T.test_3ddl()
    knav.jump_to_cell(3)
    events.add("keypressed", "down")
    events.add("keypressed", "down")
    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 6)
end

return T
