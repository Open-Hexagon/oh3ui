local events = require("ui.events")
local output = require("ui.interaction.mouse.output").active
local button_names = require("ui.interaction.mouse.button_names")

local mouse = {
    x = -1,
    y = -1,
    prev_x = -1,
    prev_y = -1,
}

---Update mouse output
function mouse.update()
    mouse.prev_x, mouse.prev_y = mouse.x, mouse.y
    mouse.x, mouse.y = love.graphics.inverseTransformPoint(love.mouse.getPosition())

    for i = 1, button_names.length do
        output[i].up = false
        output[i].down = false
    end

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
