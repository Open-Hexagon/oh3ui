local events = require("ui.events")

-- Table of mouse button names
local button_names = {
    "left",
    "right",
    "middle",
    "back",
    "forward",
}

button_names.length = #button_names

local mouse = {
    x = -1,
    y = -1,
    prev_x = -1,
    prev_y = -1,
}

-- Set up output tables
for i, name in pairs(button_names) do
    mouse[i] = { up = false, down = false, pressed = false, times = 0 }
    mouse[name] = mouse[i]
end

---Update mouse output
function mouse.update()
    -- Get mouse position and set previous position
    mouse.prev_x, mouse.prev_y = mouse.x, mouse.y
    mouse.x, mouse.y = love.graphics.inverseTransformPoint(love.mouse.getPosition())

    -- Clear the up/down fields
    for i = 1, button_names.length do
        mouse[i].up = false
        mouse[i].down = false
    end

    -- Search for press and release events and update the output
    for event in events.iterate("mouse[prm]") do
        local name, x, y, a, b, c = unpack(event)
        if name == "mousemoved" then
            local dx, dy, istouch = a, b, c
            -- todo: check
        else
            local button, istouch, presses = a, b, c
            button = mouse[button]
            button.times = presses
            if name == "mousepressed" then
                button.down = true
                button.pressed = true
            elseif name == "mousereleased" then
                button.up = true
                button.pressed = false
            end
        end
    end
end

return mouse
