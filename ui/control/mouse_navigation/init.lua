---A module that gathers mouse related events and displays them in a nice way.
---For checking mouse intersection: see sensor/init.lua

local events = require("ui.events")
local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")
local sensor = require("ui.control.mouse_navigation.sensor")

local mouse_navigation = {
    -- this frame's mouse position
    x = -1,
    y = -1,

    -- change in coordinates from last frame (not screen coordinates)
    dx = 0,
    dy = 0,

    -- wheel movement
    wheel_dx = 0,
    wheel_dy = 0,

    clicked = nil,
    holding = nil,
    dragging = nil,
    started_dragging = nil,
    stopped_dragging = nil,

    -- press location (not screen coordinates)
    drag_origin_x = nil,
    drag_origin_y = nil,
}

---@enum mouse_button
mouse_navigation.button = {
    left = 1,
    right = 2,
    middle = 3,
    back = 4,
    forward = 5,
}

---Center of the bubble that decides whether the cursor has moved too much.
---Uses screen coordinates since we don't want the bubble changing size based on UI scaling.
local press_bubble_x, press_bubble_y
local press_bubble_radius = 6

---Holds the id of the last created sensor.
local sensor_index = 0

---The sensor id that will be used to check for hovering
local current_sensor_id = 0

---Makes a new sensor element used to detect mouse hovering.
---Returns a new sensor id and sets the current_sensor_id to the new id
---@param mode? "block"|"lazy"|"pass" sensor mode
---@return integer sensor_id sensor id
function mouse_navigation.make_sensor(mode)
    cursor.place()
    sensor_index = sensor_index + 1
    draw_queue.mouse_sensor(
        sensor_index,
        mode or "block",
        placement.left,
        placement.top,
        placement.right,
        placement.bottom
    )
    current_sensor_id = sensor_index
    return sensor_index
end

---Changes the current_sensor_id to a new id.
---Can be used to revert the current_sensor_id back to a previously made sensor
---@param sensor_id integer
function mouse_navigation.change_to_sensor(sensor_id)
    if sensor_id < 1 or sensor_id > sensor_index then
        error("bad sensor id")
    end
    current_sensor_id = sensor_id
end

---Returns true if the mouse is hovering the sensor with current_sensor_id.
---@param sensor_id integer?
---@return boolean?
---@nodiscard
function mouse_navigation.is_hovering(sensor_id)
    return sensor.hover_state[sensor_id or current_sensor_id]
end

---Gets the mouse button that is holding the sensor with current_sensor_id, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_holding(sensor_id)
    if mouse_navigation.is_hovering(sensor_id) then
        return mouse_navigation.holding
    end
    return nil
end

---Gets the mouse button that clicked the sensor with current_sensor_id, if any.
---@param sensor_id integer?
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_clicked(sensor_id)
    if mouse_navigation.is_hovering(sensor_id) then
        return mouse_navigation.clicked
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

    mouse_navigation.dx, mouse_navigation.dy = 0, 0
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
            -- Record wheel movement
            mouse_navigation.wheel_dx = mouse_navigation.wheel_dx + x
            mouse_navigation.wheel_dy = mouse_navigation.wheel_dy + y
        elseif name == "mousemoved" then
            local dx, dy, istouch = a, b, c

            -- Transition from clicking to dragging if mouse moves too far
            -- Using L1 distance, so the bubble is not actually a circle, it's a diamond <>.
            if
                mouse_navigation.holding
                and math.abs(press_bubble_x - screen_x) + math.abs(press_bubble_y - screen_y) >= press_bubble_radius
            then
                -- start dragging
                mouse_navigation.started_dragging = mouse_navigation.holding
                mouse_navigation.dragging = mouse_navigation.holding
                mouse_navigation.drag_origin_x = mouse_navigation.x
                mouse_navigation.drag_origin_y = mouse_navigation.y
                -- stop holding
                mouse_navigation.holding = nil
            end

            -- Record mouse movement
            -- Using the event dx, dy happens to work better if the mouse is being repositioned manually.
            mouse_navigation.dx, mouse_navigation.dy = love.graphics.inverseTransformPoint(dx, dy)
        else
            local button_id, istouch, presses = a, b, c

            if name == "mousepressed" then
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
                end
            elseif name == "mousereleased" then
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
                end
            end
        end
    end

    -- evaluate update the hover_set
    sensor.evaluate(screen_x, screen_y)
    sensor_index = 0
end

return mouse_navigation
