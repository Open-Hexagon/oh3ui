local event_queue = require("ui.event_queue")

local click = {}

-- true when the following happens:
-- 1. mouse is pressed at a certain position
-- 2. mouse doesn't move more than 'move_threshold' from that location
--    (moving away and back again is also invalid)
-- 3. mouse is released
click.clicking = false

-- state for that interaction
local is_down = false
local press_position = { x = 0, y = 0 }
local moved_too_much = false
local move_threshold = 10

---update clicking state
function click.update()
    click.clicking = false
    for event in event_queue.iterate("mouse.*") do
        local name, x, y = unpack(event)
        if name == "mousepressed" then
            is_down = true
            moved_too_much = false
            press_position.x = x
            press_position.y = y
        elseif name == "mousemoved" then
            if (x - press_position.x) ^ 2 + (y - press_position.y) ^ 2 > move_threshold then
                moved_too_much = true
            end
        elseif name == "mousereleased" and is_down then
            is_down = false
            click.clicking = not moved_too_much
        end
    end
end

return click
