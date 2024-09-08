local events = require("ui.events")
local button_names = require("ui.interaction.mouse.button_names")
local output = require("ui.interaction.mouse.output").active -- we only care about updating the active table

local mouse = {
    x = -1,
    y = -1,
    prev_x = -1,
    prev_y = -1,
}

---Update mouse output
function mouse.update()
    -- Get mouse position and set previous position
    mouse.prev_x, mouse.prev_y = mouse.x, mouse.y
    mouse.x, mouse.y = love.graphics.inverseTransformPoint(love.mouse.getPosition())

    -- Clear the output table
    for i = 1, button_names.length do
        output[i].up = false
        output[i].down = false
    end

    -- Search for press and release events and update the output
    for event in events.iterate("mouse[pr]") do
        local name, x, y, button, istouch, presses = unpack(event)
        button = output[button]
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

return mouse
