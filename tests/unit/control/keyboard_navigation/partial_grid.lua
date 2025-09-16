local knav = require("ui.control.keyboard_navigation")
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local unittest = require("tests.unittest")
local monkeypatch = require("tests.monkeypatch")

local common = require("tests.unit.control.keyboard_navigation.common")

local T = {}

local is_down = false

function T.set_up_case()
    love.keyboard.isDown = monkeypatch.replace(love.keyboard.isDown, function(a, b)
        if a == "lshift" and b == "rshift" then
            return is_down
        end
        return false
    end)
end

function T.tear_down_case()
    love.keyboard.isDown = monkeypatch.get_original(love.keyboard.isDown)
end

function T.set_up()
    --[[
        Grid setup:
        0 0 3
        4 0 0
        7 8 0
    ]]

    control_data.current_layer_is_active = true

    knav.make_cell()

    knav.make_cell()

    knav.make_cell()
    knav.grid_cell(3, 1)

    knav.make_cell()
    knav.grid_cell(1, 2)

    knav.make_cell()

    knav.make_cell()

    knav.make_cell()
    knav.grid_cell(1, 3)

    knav.make_cell()
    knav.grid_cell(2, 3)

    knav.make_cell()

    control_data.current_layer_is_active = false
end

function T.tear_down()
    common.reset_all()
end

function T.test_initial_move()
    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 3)
    knav.deselect()
    events.clear()

    events.add("keypressed", "down")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 3)
    knav.deselect()
    events.clear()

    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 8)
    knav.deselect()
    events.clear()

    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 8)
    knav.deselect()
    events.clear()
end

function T.test_tabbing()
    local id, x, y
    is_down = false
    events.add("keypressed", "tab")
    events.add("keypressed", "tab")

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()

    unittest.assert(id == 2)
    unittest.assert(x == nil)
    unittest.assert(y == nil)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 4)
    unittest.assert(x == 1)
    unittest.assert(y == 2)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 6)
    unittest.assert(x == nil)
    unittest.assert(y == nil)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 8)
    unittest.assert(x == 2)
    unittest.assert(y == 3)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 1)
    unittest.assert(x == nil)
    unittest.assert(y == nil)
end

function T.test_shift_tabbing()
    local id, x, y
    is_down = true
    events.add("keypressed", "tab")
    events.add("keypressed", "tab")

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 8)
    unittest.assert(x == 2)
    unittest.assert(y == 3)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 6)
    unittest.assert(x == nil)
    unittest.assert(y == nil)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 4)
    unittest.assert(x == 1)
    unittest.assert(y == 2)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 2)
    unittest.assert(x == nil)
    unittest.assert(y == nil)

    knav.evaluate()
    id, x, y = common.get_selected_cell_info()
    unittest.assert(id == 9)
    unittest.assert(x == nil)
    unittest.assert(y == nil)
end

function T.test_pageup()
    knav.set_page_length(3)
    events.add("keypressed", "pageup")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 9)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 6)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 3)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 1)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 1)
end

function T.test_pagedn()
    knav.set_page_length(3)
    events.add("keypressed", "pagedown")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 1)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 4)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 7)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 9)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 9)
end

function T.test_home()
    events.add("keypressed", "home")
    knav.jump_to_cell(5)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 1)
end

function T.test_end()
    events.add("keypressed", "end")
    knav.jump_to_cell(5)
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 9)
end

function T.test_using_arrow_keys_on_cell_with_no_grid_position()
    knav.jump_to_cell(5)
    events.add("keypressed", "right")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 6)
    events.clear()

    knav.jump_to_cell(5)
    events.add("keypressed", "down")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 6)
    events.clear()

    knav.jump_to_cell(5)
    events.add("keypressed", "left")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 4)
    events.clear()

    knav.jump_to_cell(5)
    events.add("keypressed", "up")
    knav.evaluate()
    unittest.assert(common.get_selected_cell_info() == 4)
    events.clear()
end

return T
