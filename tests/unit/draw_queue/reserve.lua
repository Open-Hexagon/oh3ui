local unittest = require("tests.unittest")
local draw_queue = require("ui.draw_queue")
local history = require("tests.history")
local draw = require("ui.draw_queue.draw")
local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")
local common = require("tests.unit.draw_queue.misc")

local T = {}

T.set_up_case = common.set_up_case
T.set_up = common.set_up
T.tear_down_case = common.tear_down_case

function T.test_reserve()
    local p = draw_data.make_placement(0, 0, 0, 0)

    unittest.assert_error(draw_data.next_takes_reservation, nil, 0)

    unittest.assert_error(draw_data.reserve_draw_slots, nil, -1)

    local r = draw_data.reserve_draw_slots(3)

    draw_data.add_draw_operation(op_ids.mouse_sensor, p, 1, 0)

    draw_data.next_takes_reservation(r)
    draw_data.add_draw_operation(op_ids.mouse_sensor, p, 2, 0)
    draw_data.next_takes_reservation(r)
    draw_data.add_draw_operation(op_ids.mouse_sensor, p, 3, 0)
    draw_data.next_takes_reservation(r)
    draw_data.add_draw_operation(op_ids.mouse_sensor, p, 4, 0)

    draw_data.next_takes_reservation(r)
    unittest.assert_error(draw_data.add_draw_operation, nil, op_ids.mouse_sensor, p, 5, 0)

    draw()

    unittest.assert_equal_lists(history.get(-3), { "sp", 2, 0, 0, 0, 0, 0 })
    unittest.assert_equal_lists(history.get(-2), { "sp", 3, 0, 0, 0, 0, 0 })
    unittest.assert_equal_lists(history.get(-1), { "sp", 4, 0, 0, 0, 0, 0 })
    unittest.assert_equal_lists(history.get(0), { "sp", 1, 0, 0, 0, 0, 0 })
end

function T.test_reserve_gap()
    local r = draw_data.reserve_draw_slots(1)

    unittest.assert_error(draw)

    -- clean up before finishing test
    draw_data.next_takes_reservation(r)
    draw_queue.nop()

    draw()
end

return T
