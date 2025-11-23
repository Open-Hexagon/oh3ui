local unittest = require("tests.unittest")
local sensor = require("ui.control.sensor")
local smode = sensor.sensor_mode
local bor = require("bit").bor

local T = {}

--[[
Sensor arrangement side view with desired outcomes

Position:                         1    2    3    4
                                  |    |    |    |
7. pass+disable                 --x----x----x----x--
                                  |    |    |    |
6. draggable+lazy+disable       -------d-------  |
                                  |    |    |    |
5. draggable+lazy               --D--  |    |    |
                                  |    |    |    |
4. draggable+blocking+disable   --d--  |    |    |
                                       |    |    |
3. blocking+lazy+disable               |  --x--  |
                                       |         |
2. blocking                            |  -----  |
                                       |         |
1. pass                         -------X---------X--

]]

function T.set_up()
    sensor.enable_intersection_checks()
    sensor.push(1, 0, 0, 0, 40, 10)
    sensor.push(2, smode.block, 20, 0, 30, 10)
    sensor.push(3, bor(smode.block, smode.lazy, smode.disable), 20, 0, 30, 10)
    sensor.push(4, bor(smode.draggable, smode.block, smode.disable), 0, 0, 10, 10)
    sensor.push(5, bor(smode.draggable, smode.lazy), 0, 0, 10, 10)
    sensor.push(6, bor(smode.draggable, smode.lazy, smode.disable), 0, 0, 30, 10)
    sensor.push(7, smode.disable, 0, 0, 40, 10)
end

function T.tear_down()
    sensor.clear()
end

function T.test_position_1()
    sensor.evaluate(5, 5)
    unittest.assert(not sensor.hover_set[7])
    unittest.assert(not sensor.hover_set[6])
    unittest.assert(sensor.hover_set[5])
    unittest.assert(not sensor.hover_set[4])
    unittest.assert(not sensor.hover_set[3])
    unittest.assert(not sensor.hover_set[2])
    unittest.assert(not sensor.hover_set[1])
    -- because the sensor 4 is disabled, dragging is deferred to sensor 5
    unittest.assert(sensor.preemptive_drag_id == 5)
end

function T.test_position_2()
    sensor.evaluate(15, 5)
    unittest.assert(not sensor.hover_set[7])
    unittest.assert(not sensor.hover_set[6])
    unittest.assert(not sensor.hover_set[5])
    unittest.assert(not sensor.hover_set[4])
    unittest.assert(not sensor.hover_set[3])
    unittest.assert(not sensor.hover_set[2])
    unittest.assert(sensor.hover_set[1])
    unittest.assert(sensor.preemptive_drag_id == nil)
end

function T.test_position_3()
    sensor.evaluate(25, 5)
    unittest.assert(not sensor.hover_set[7])
    unittest.assert(not sensor.hover_set[6])
    unittest.assert(not sensor.hover_set[5])
    unittest.assert(not sensor.hover_set[4])
    unittest.assert(not sensor.hover_set[3])
    unittest.assert(not sensor.hover_set[2])
    unittest.assert(not sensor.hover_set[1])
    unittest.assert(sensor.preemptive_drag_id == nil)
end

function T.test_position_4()
    sensor.evaluate(35, 5)
    unittest.assert(not sensor.hover_set[7])
    unittest.assert(not sensor.hover_set[6])
    unittest.assert(not sensor.hover_set[5])
    unittest.assert(not sensor.hover_set[4])
    unittest.assert(not sensor.hover_set[3])
    unittest.assert(not sensor.hover_set[2])
    unittest.assert(sensor.hover_set[1])
    unittest.assert(sensor.preemptive_drag_id == nil)
end

return T
