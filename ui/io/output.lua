local input = require("ui.io.input")


-- The output table reads parameters from the input table and updates itself.
-- elements should typically only read from the output table
local output = {}

function output.update()
    -- position
    output.left = input.x - input.anchor.x * input.width
    output.top = input.y - input.anchor.y * input.height
    output.right = input.x + (1 - input.anchor.x) * input.width
    output.bottom = input.y + (1 - input.anchor.y) * input.height

    -- mouse events
    output.pressed = false
    output.released = false
    output.hovering = false


    output.hovering = false
    output.clicked = false
    
    output.areas = output.areas or {}
    output.current_area_index = 0

end

return output
