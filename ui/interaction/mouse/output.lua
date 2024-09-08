-- The output tables for mouse events

local button_names = require("ui.interaction.mouse.button_names")

local mouse_output = {}

-- The blank table holds output values that are as if no mouse events have occurred.
-- The cursor output is set to the blank table when the mouse isn't inside the cursor.
local blank = { up = false, down = false, pressed = false, times = 0 }
mouse_output.blank = {}

-- The active table holds the actual mouse event outputs.
-- The cursor output is set to this table when the mouse is inside the cursor.
mouse_output.active = {}

for i, name in pairs(button_names) do
    -- Set up the blank table
    mouse_output.blank[i] = blank
    mouse_output.blank[name] = blank

    -- Set up the active table
    local active = { up = false, down = false, pressed = false, times = 0 }
    mouse_output.active[i] = active
    mouse_output.active[name] = active
end

-- These flags never have to change because of the table swapping.
mouse_output.blank.hovering = false
mouse_output.active.hovering = true

-- The blank and active tables also hold, "enter", and "exit" fields,
-- but these are set by cursor.commit and are ignored by the mouse interation module.

return mouse_output
