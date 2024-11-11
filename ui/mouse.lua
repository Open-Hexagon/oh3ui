---A module that gathers mouse related events and displays them in a nice way.
---For checking mouse intersection: see sensor/init.lua

local events = require("ui.events")

local mouse

do
    local LEFT_BUTTON, RIGHT_BUTTON, MIDDLE_BUTTON, BACK_BUTTON, FORWARD_BUTTON = 1, 2, 3, 4, 5
    local BUTTON_COUNT = 5

    local function m()
        return { up = false, down = false, pressed = false, times = 0 }
    end

    local temp = {}

    for i = 1, BUTTON_COUNT do
        temp[i] = m()
    end

    mouse = {
        -- mouse button ids
        LEFT = LEFT_BUTTON,
        RIGHT = RIGHT_BUTTON,
        MIDDLE = MIDDLE_BUTTON,
        BACK = BACK_BUTTON,
        FORWARD = FORWARD_BUTTON,

        -- number of mouse buttons
        BUTTON_COUNT = BUTTON_COUNT,

        -- this frame's mouse position
        x = -1,
        y = -1,

        -- this frame's mouse position (screen coordinates)
        screen_x = -1,
        screen_y = -1,

        -- change in coordinates from last frame
        dx = 0,
        dy = 0,
        moved = false,

        wheel_dx = 0,
        wheel_dy = 0,

        -- any mouse button up/down/pressed states
        any = m(),

        -- named individual mouse button up/down/pressed states
        left = temp[LEFT_BUTTON],
        right = temp[RIGHT_BUTTON],
        middle = temp[MIDDLE_BUTTON],
        back = temp[BACK_BUTTON],
        forward = temp[FORWARD_BUTTON],

        -- numbered individual mouse button up/down/pressed states
        [LEFT_BUTTON] = temp[LEFT_BUTTON],
        [RIGHT_BUTTON] = temp[RIGHT_BUTTON],
        [MIDDLE_BUTTON] = temp[MIDDLE_BUTTON],
        [BACK_BUTTON] = temp[BACK_BUTTON],
        [FORWARD_BUTTON] = temp[FORWARD_BUTTON],

        -- holds the mouse button id of the last button pressed or released this frame
        last_down = nil,
        last_up = nil,
    }
end

---@param event_name string
local function event_filter(event_name)
    return string.match(event_name, "mouse[prm]") or event_name == "wheelmoved"
end

---Update mouse output
function mouse.update()
    -- Get mouse positions
    mouse.screen_x, mouse.screen_y = love.mouse.getPosition()
    mouse.x, mouse.y = love.graphics.inverseTransformPoint(mouse.screen_x, mouse.screen_y)

    -- Clear the up/down fields
    for i = 1, mouse.BUTTON_COUNT do
        mouse[i].up = false
        mouse[i].down = false
    end
    mouse.last_down = nil
    mouse.last_up = nil

    mouse.dx, mouse.dy = 0, 0
    mouse.moved = false
    mouse.wheel_dx, mouse.wheel_dy = 0, 0

    -- Search for press and release events and update the left, right, middle, back, and forward tables
    -- Also update which button was last released and last pressed.
    for event in events.iterate(event_filter) do
        local name, x, y, a, b, c = unpack(event)
        if name == "wheelmoved" then
            mouse.wheel_dx = mouse.wheel_dx + x
            mouse.wheel_dy = mouse.wheel_dy + y
        elseif name == "mousemoved" then
            local dx, dy, istouch = a, b, c

            -- using the event dx, dy happens to work better if the mouse is being repositioned
            mouse.dx, mouse.dy = love.graphics.inverseTransformPoint(dx, dy)
            mouse.moved = true

            -- todo Some behavior is different for touchscreens
        else
            local button_id, istouch, presses = a, b, c
            local button = mouse[button_id]
            button.times = presses
            if name == "mousepressed" then
                button.down = true
                button.pressed = true
                mouse.last_down = button_id
            elseif name == "mousereleased" then
                button.up = true
                button.pressed = false
                mouse.last_up = button_id
            end
        end
    end

    -- Update the any table
    mouse.any.up = false
    mouse.any.down = false
    mouse.any.pressed = false
    for i = 1, mouse.BUTTON_COUNT do
        mouse.any.up = mouse.any.up or mouse[i].up
        mouse.any.down = mouse.any.down or mouse[i].down
        mouse.any.pressed = mouse.any.pressed or mouse[i].pressed
    end
end

return mouse
