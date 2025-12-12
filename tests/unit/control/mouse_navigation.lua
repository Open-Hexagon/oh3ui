local events = require("ui.events")
local mnav = require("ui.control.mouse_navigation")
local monkeypatch = require("tests.monkeypatch")
local unittest = require("tests.unittest")
local control_data = require("ui.control.control_data")
local sensor = require("ui.control.sensor")
local extmath = require("extmath")

local T = {}

local mouse_is_visible
local msx, msy = 0, 0

function T.set_up_case()
    love.mouse.setVisible = monkeypatch.replace(love.mouse.setVisible, function(a)
        mouse_is_visible = a
    end)
    love.mouse.getPosition = monkeypatch.replace(love.mouse.getPosition, function()
        return msx, msy
    end)
end

local function zero()
    msx, msy = 0, 0
end

function T.set_up()
    mouse_is_visible = nil
    zero()
    control_data.last_used_control_method = "none"
    events.clear()

    mnav.x = -1
    mnav.y = -1
    mnav.screen_dx = 0
    mnav.screen_dy = 0
    mnav.wheel_dx = 0
    mnav.wheel_dy = 0
    mnav.clicked = nil
    mnav.holding = nil
    mnav.dragging = nil
    mnav.started_dragging = nil
    mnav.stopped_dragging = nil
    mnav.press_x = -1
    mnav.press_y = -1

    love.graphics.origin()
end

function T.tear_down_case()
    love.mouse.setVisible = monkeypatch.get_original(love.mouse.setVisible)
    love.mouse.getPosition = monkeypatch.get_original(love.mouse.getPosition)
    T.set_up()
    sensor.do_intersections = true
end

local function move(x, y, istouch)
    msx, msy = msx + x, msy + y
    events.add("mousemoved", msx, msy, x, y, istouch)
end

local function down(button_id, istouch, presses)
    events.add("mousepressed", msx, msy, button_id, istouch, presses)
end

local function up(button_id, istouch, presses)
    events.add("mousereleased", msx, msy, button_id, istouch, presses)
end

local function run()
    mnav.evaluate()
    events.clear()
end

function T.test_wheel_move()
    events.add("wheelmoved", 10, 10)
    events.add("wheelmoved", -5, 0)
    events.add("wheelmoved", 0, -5)

    run()

    unittest.assert(control_data.last_used_control_method == "mouse")
    unittest.assert(mnav.wheel_dx == 5)
    unittest.assert(mnav.wheel_dy == 5)
end

function T.test_mouse_move()
    love.graphics.scale(2)

    sensor.do_intersections = false

    move(10, 10)
    move(-5, 0)
    move(0, -5)

    run()

    unittest.assert(sensor.do_intersections == true)
    unittest.assert(mouse_is_visible == true)
    unittest.assert(control_data.last_used_control_method == "mouse")
    unittest.assert(mnav.screen_dx == 5)
    unittest.assert(mnav.screen_dy == 5)

    unittest.assert(mnav.x == 2.5)
    unittest.assert(mnav.y == 2.5)
end

function T.test_simple_click()
    love.graphics.scale(2)

    move(30, 30)
    run()

    for i = 1, 5 do
        control_data.last_used_control_method = "none"
        down(i)
        run()

        unittest.assert(control_data.last_used_control_method == "mouse")
        unittest.assert(mnav.holding == i)
        unittest.assert(mnav.clicked == nil)
        unittest.assert(mnav.press_x == 15)
        unittest.assert(mnav.press_y == 15)

        control_data.last_used_control_method = "none"
        up(i)
        run()

        unittest.assert(control_data.last_used_control_method == "mouse")
        unittest.assert(mnav.holding == nil)
        unittest.assert(mnav.clicked == i)
        unittest.assert(mnav.press_x == 15)
        unittest.assert(mnav.press_y == 15)

        control_data.last_used_control_method = "none"
        run()

        unittest.assert(control_data.last_used_control_method == "none")
        unittest.assert(mnav.holding == nil)
        unittest.assert(mnav.clicked == nil)
        unittest.assert(mnav.press_x == 15) -- these values stay
        unittest.assert(mnav.press_y == 15)
    end
end

local press_bubble_radius = 4
local press_bubble_touch_radius = 6

for test, values in pairs({
    test_dragging_x = { bubble_radius = press_bubble_radius, axis = "x", is_touch = false },
    test_touch_dragging_x = { bubble_radius = press_bubble_touch_radius, axis = "x", is_touch = true },
    test_dragging_y = { bubble_radius = press_bubble_radius, axis = "y", is_touch = false },
    test_touch_dragging_y = { bubble_radius = press_bubble_touch_radius, axis = "y", is_touch = true },
}) do
    T[test] = function()
        for u = -20, 20 do
            local dist = math.abs(u)
            love.graphics.scale(math.max(0.5, dist / 2)) -- this should not affect results

            zero()

            down(1)
            run()
            unittest.assert(mnav.clicked == nil)
            unittest.assert(mnav.holding == 1)
            unittest.assert(mnav.dragging == nil)
            unittest.assert(mnav.started_dragging == nil)
            unittest.assert(mnav.stopped_dragging == nil)

            for i = 1, dist do
                if values.axis == "x" then
                    move(extmath.sgn(u), 0, values.is_touch)
                else
                    move(0, extmath.sgn(u), values.is_touch)
                end
                run()

                if i <= values.bubble_radius then
                    unittest.assert(mnav.clicked == nil)
                    unittest.assert(mnav.holding == 1, tostring(mnav.holding))
                    unittest.assert(mnav.dragging == nil)
                    unittest.assert(mnav.started_dragging == nil)
                    unittest.assert(mnav.stopped_dragging == nil)
                elseif i == values.bubble_radius + 1 then
                    unittest.assert(mnav.clicked == nil)
                    unittest.assert(mnav.holding == nil)
                    unittest.assert(mnav.dragging == 1)
                    unittest.assert(mnav.started_dragging == 1)
                    unittest.assert(mnav.stopped_dragging == nil)
                else
                    unittest.assert(mnav.clicked == nil)
                    unittest.assert(mnav.holding == nil)
                    unittest.assert(mnav.dragging == 1)
                    unittest.assert(mnav.started_dragging == nil)
                    unittest.assert(mnav.stopped_dragging == nil)
                end
            end

            up(1)
            run()

            if dist <= values.bubble_radius then
                unittest.assert(mnav.clicked == 1)
                unittest.assert(mnav.holding == nil)
                unittest.assert(mnav.dragging == nil)
                unittest.assert(mnav.started_dragging == nil)
                unittest.assert(mnav.stopped_dragging == nil)
            else
                unittest.assert(mnav.clicked == nil)
                unittest.assert(mnav.holding == nil)
                unittest.assert(mnav.dragging == nil)
                unittest.assert(mnav.started_dragging == nil)
                unittest.assert(mnav.stopped_dragging == 1)
            end

            love.graphics.origin()
        end
    end
end

-- degenerate cases

function T.test_click_in_one_frame() end

function T.test_slight_drag_click_in_one_frame() end

function T.test_drag_in_one_frame() end

function T.test_isolated_release() end

return T
