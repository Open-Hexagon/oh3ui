local upvalue = require("tests.upvalue")
local knav = require("ui.control.keyboard_navigation")
local mnav = require("ui.control.mouse_navigation")
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")

local T = {}

function T.set_up_case()
    control_data.current_layer_is_active = true

    knav.make_cell()
    knav.grid_cell(1, 1, 1, 2)

    knav.make_cell()
    knav.grid_cell(2, 1)

    knav.make_cell()
    knav.grid_cell(3, 1)

    knav.make_cell()
    knav.grid_cell(2, 2, 2, 1)
    control_data.current_layer_is_active = false
end

function T.tear_down_case()
    knav.reset()
end

--[[

1 2 3
1 4 4
]]

function T.set_up() end

function T.tear_down()
    knav.deselect()
    events.clear()
end

function T.test_initial_move()
    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(upvalue.get_by_name(knav.deselect, "selected_cell_id") == 1)
    knav.deselect()
    events.clear()

    events.add("keypressed", "down")
    knav.evaluate()
    unittest.assert(upvalue.get_by_name(knav.deselect, "selected_cell_id") == 1)
    knav.deselect()
    events.clear()

    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(upvalue.get_by_name(knav.deselect, "selected_cell_id") == 4)
    knav.deselect()
    events.clear()

    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(upvalue.get_by_name(knav.deselect, "selected_cell_id") == 4)
    knav.deselect()
    events.clear()
end

function T.test_mouse_hiding() end

return T
