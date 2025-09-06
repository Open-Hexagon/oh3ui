---A module that gathers mouse related events and displays them in a nice way.
---For checking mouse intersection: see sensor/init.lua

local events = require("ui.events")
local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")
local sensor = require("ui.control.mouse_navigation.sensor")
local bit = require("bit")
local bor = bit.bor
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local control_method = shared_data.enums.control_method

local mouse_navigation = {
    -- this frame's mouse position (not screen coordinates)
    x = -1,
    y = -1,

    -- change in coordinates from last frame (screen coordinates)
    screen_dx = 0,
    screen_dy = 0,

    -- wheel movement
    wheel_dx = 0,
    wheel_dy = 0,

    -- these fields can be read directly if you don't care where the clicks/holds/drags are
    clicked = nil,
    holding = nil,

    dragging = nil,
    started_dragging = nil,
    stopped_dragging = nil,

    -- last press location (not screen coordinates)
    press_x = nil,
    press_y = nil,
}

mouse_navigation.sensor_mode = sensor.sensor_mode

---@enum mouse_button
mouse_navigation.buttons = {
    left = 1,
    right = 2,
    middle = 3,
    back = 4,
    forward = 5,
}

---The id of the latest dragged sensor.
---This is not erased when dragging stops.
local latest_dragging_id

---Center of the bubble that decides whether the cursor has moved too much.
---Uses screen coordinates since we don't want the bubble changing size based on UI scaling.
local press_bubble_x, press_bubble_y
local press_bubble_radius = 2
local press_bubble_touch_radius = 6

---Holds the id of the last created sensor.
---Increments as sensors are made.
local last_sensor_id = 0

---Holds the last manually created sensor id.
---Decreases as ids are declared (to avoid collisions with the automatically created ids)
local last_manual_sensor_id = 0

---Returns a new sensor id. Can be used to forward declare sensor ids.
---@return integer
---@nodiscard
function mouse_navigation.declare_sensor_id()
    last_manual_sensor_id = last_manual_sensor_id - 1
    control_data.current_sensor_id = last_manual_sensor_id
    return last_manual_sensor_id
end

---Makes a new sensor element used to detect mouse hovering.
---Returns a new sensor id and sets the current_sensor_id to the new id
---@param sensor_id? integer forces this sensor to be created with a certain id (must be negative)
---@param ... integer sensor modes
---@return integer sensor_id sensor id
function mouse_navigation.make_sensor(sensor_id, ...)
    cursor.place()
    if sensor_id then
        if sensor_id >= 0 then
            error(string.format("sensor id %d cannot be used", sensor_id))
        end
        control_data.current_sensor_id = sensor_id
    else
        last_sensor_id = last_sensor_id + 1
        control_data.current_sensor_id = last_sensor_id
    end
    if not control_data.suppress_controls then
        draw_queue.mouse_sensor(
            control_data.current_sensor_id,
            bor(0, ...),
            placement.left,
            placement.top,
            placement.right,
            placement.bottom
        )
    end
    return control_data.current_sensor_id
end

---Changes the currently recognized sensor to a new id.
---Can be used to revert the current sensor back to a previously made sensor
---@param sensor_id integer
function mouse_navigation.change_to_sensor(sensor_id)
    if sensor_id < last_manual_sensor_id or sensor_id > last_sensor_id then
        error("bad sensor id")
    end
    control_data.current_sensor_id = sensor_id
end

---Restarts navigation for layer transitions
mouse_navigation.lt_restart = sensor.clear

---Returns true if the mouse is hovering the current sensor.
---The hover set is only accurate to the previous frame but also isn't destroyed until the end of the frame.
---Thus, you can access sensor ids from the previous frame that have yet to be created this frame.
---@param sensor_id integer?
---@return boolean
---@nodiscard
function mouse_navigation.is_hovering(sensor_id)
    return sensor.hover_set[sensor_id or control_data.current_sensor_id] or false
end

---Gets the mouse button that is holding the current sensor, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_holding(sensor_id)
    if mouse_navigation.is_hovering(sensor_id) then
        return mouse_navigation.holding
    end
    return nil
end

---Gets the mouse button that clicked the current sensor, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_clicked(sensor_id)
    if mouse_navigation.is_hovering(sensor_id) then
        return mouse_navigation.clicked
    end
    return nil
end

---Gets the mouse button is dragging the current sensor, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_dragging(sensor_id)
    if mouse_navigation.dragging and latest_dragging_id == (sensor_id or control_data.current_sensor_id) then
        return mouse_navigation.dragging
    end
    return nil
end

---Gets the mouse button that just started dragging the current sensor, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_started_dragging(sensor_id)
    if mouse_navigation.started_dragging and latest_dragging_id == (sensor_id or control_data.current_sensor_id) then
        return mouse_navigation.started_dragging
    end
    return nil
end

---Gets the mouse button that just stopped dragging the current sensor, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_stopped_dragging(sensor_id)
    if mouse_navigation.stopped_dragging and latest_dragging_id == (sensor_id or control_data.current_sensor_id) then
        return mouse_navigation.stopped_dragging
    end
    return nil
end

mouse_navigation.hover_off = sensor.disable_intersection_checks
mouse_navigation.hover_on = sensor.enable_intersection_checks

---@param event_name string
local function event_filter(event_name)
    return string.match(event_name, "mouse[prm]") or event_name == "wheelmoved"
end

---Update mouse output. Should be run at the start of a frame.
function mouse_navigation.evaluate()
    -- Get mouse positions
    local screen_x, screen_y = love.mouse.getPosition()
    mouse_navigation.x, mouse_navigation.y = love.graphics.inverseTransformPoint(screen_x, screen_y)

    mouse_navigation.screen_dx, mouse_navigation.screen_dy = 0, 0
    mouse_navigation.wheel_dx, mouse_navigation.wheel_dy = 0, 0

    -- these fields only survive for 1 frame
    mouse_navigation.clicked = nil
    mouse_navigation.started_dragging = nil
    mouse_navigation.stopped_dragging = nil

    -- evaluate global hold/click/drag behavior from mouse events
    -- record mouse and wheel movement
    for event in events.iterate(event_filter) do
        local name, x, y, a, b, c = unpack(event)

        if name == "wheelmoved" then
            -- Scrolling updates the last used method
            control_data.last_used_control_method = control_method.mouse

            -- Record wheel movement
            mouse_navigation.wheel_dx = mouse_navigation.wheel_dx + x
            mouse_navigation.wheel_dy = mouse_navigation.wheel_dy + y
        elseif name == "mousemoved" then
            -- Any mouse movement sets makes the cursor visible
            love.mouse.setVisible(true)
            mouse_navigation.hover_on()

            local dx, dy, istouch = a, b, c

            -- Transition from clicking to dragging if mouse moves far enough while holding
            -- Using L1 distance, so the bubble is not actually a circle, it's a diamond <>.
            if
                mouse_navigation.holding
                and math.abs(press_bubble_x - screen_x) + math.abs(press_bubble_y - screen_y)
                    >= (istouch and press_bubble_touch_radius or press_bubble_radius)
            then
                -- start dragging
                mouse_navigation.started_dragging = mouse_navigation.holding
                mouse_navigation.dragging = mouse_navigation.holding
                -- Save the preemptive_drag_id from sensor so we remember what we're dragging, even if the mouse unhovers the sensors
                latest_dragging_id = sensor.preemptive_drag_id

                -- stop holding
                mouse_navigation.holding = nil

                -- disable hover checks while dragging
                mouse_navigation.hover_off()
            end

            -- Record mouse movement
            -- Using the event dx, dy happens to work better if the mouse is being repositioned manually.
            mouse_navigation.screen_dx, mouse_navigation.screen_dy =
                mouse_navigation.screen_dx + dx, mouse_navigation.screen_dy + dy
        else
            local button_id, istouch, presses = a, b, c

            if name == "mousepressed" then
                -- Pressing updates the last used method
                control_data.last_used_control_method = control_method.mouse

                if mouse_navigation.holding then
                    -- Pressing another button while holding stops holding
                    mouse_navigation.holding = nil
                elseif mouse_navigation.dragging then
                    -- Pressing another button while dragging stops dragging
                    mouse_navigation.stopped_dragging = mouse_navigation.dragging
                    mouse_navigation.dragging = nil
                else
                    -- Pressing a button while not already holding or dragging starts holding
                    mouse_navigation.holding = button_id
                    press_bubble_x = screen_x
                    press_bubble_y = screen_y
                    mouse_navigation.press_x = mouse_navigation.x
                    mouse_navigation.press_y = mouse_navigation.y
                end
            elseif name == "mousereleased" then
                -- Releasing updates the last used method
                control_data.last_used_control_method = control_method.mouse

                if mouse_navigation.holding then
                    -- Releasing the same button that is being held is a click. If not then holding is stopped.
                    if button_id == mouse_navigation.holding then
                        mouse_navigation.clicked = button_id
                    end
                    mouse_navigation.holding = nil
                elseif mouse_navigation.dragging then
                    -- Releasing a button while dragging stops dragging
                    mouse_navigation.stopped_dragging = mouse_navigation.dragging
                    mouse_navigation.dragging = nil

                    -- enable hover checks
                    mouse_navigation.hover_on()
                end
            end
        end
    end

    -- evaluate the hover_set
    if mouse_navigation.holding then
        ---If we're holding the button, use press bubble origin instead.
        ---This ensures that if you press on an element and try to drag, your drag will still be
        ---detected even if the cursor leaves the element bounds before it leaves the press bubble.
        ---This happens when the cursor is very close to the edge of an element.
        sensor.evaluate(press_bubble_x, press_bubble_y)
    else
        sensor.evaluate(screen_x, screen_y)
    end

    sensor.clear()
    last_sensor_id = 0
    last_manual_sensor_id = 0
end

return mouse_navigation
