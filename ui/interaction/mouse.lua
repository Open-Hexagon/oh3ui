---A broadcasting module that updates mouse position and button states.
---For checking mouse intersection: see cursor.lua

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
        LEFT_BUTTON = LEFT_BUTTON,
        RIGHT_BUTTON = RIGHT_BUTTON,
        MIDDLE_BUTTON = MIDDLE_BUTTON,
        BACK_BUTTON = BACK_BUTTON,
        FORWARD_BUTTON = FORWARD_BUTTON,

        -- number of mouse buttons
        BUTTON_COUNT = BUTTON_COUNT,

        -- this frame's mouse position
        x = -1,
        y = -1,

        -- the previous frame's mouse position
        prev_x = -1,
        prev_y = -1,

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

---Update mouse output
function mouse.update()
    -- Get mouse position and set previous position
    mouse.prev_x, mouse.prev_y = mouse.x, mouse.y
    mouse.x, mouse.y = love.graphics.inverseTransformPoint(love.mouse.getPosition())

    -- Clear the up/down fields
    for i = 1, mouse.BUTTON_COUNT do
        mouse[i].up = false
        mouse[i].down = false
    end
    mouse.last_down = nil
    mouse.last_up = nil

    -- Search for press and release events and update the left, right, middle, back, and forward tables
    -- Also update which button was last released and last pressed.
    for event in events.iterate("mouse[prm]") do
        local name, x, y, a, b, c = unpack(event)
        if name == "mousemoved" then
            local dx, dy, istouch = a, b, c
            -- todo
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
