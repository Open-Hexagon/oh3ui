---Sensors are elements that deal with user input.
---They are invisible and never create draw operations.
---The sensor module itself checks for mouse intersections.
---For checking mouse buttons, see mouse.lua.

local edge = require("ui.cursor").edge
local mouse = require("ui.mouse")

local sensor = {
    -- If false, disables mouse intersection checks and the enter, exit, and hovering fields will always be false.
    do_intersections = true,

    -- * should be read only
    enter = false,
    exit = false,
    hovering = false,
}

---Check and update whether the mouse is intersecting the cursor (i.e. the mouse is hovering the cursor).
---Also detects if the mouse just entered or exited the cursor area.
---Can be disabled by setting `sensor.do_intersections` to false.
---Should be preceded by a `cursor.place()` of some sort.
function sensor.update_mouse_intersect()
    if not sensor.do_intersections then
        sensor.enter = false
        sensor.exit = false
        sensor.hovering = false
        return
    end

    local hovering_before = mouse.prev_x >= edge.left
        and mouse.prev_x < edge.right
        and mouse.prev_y >= edge.top
        and mouse.prev_y < edge.bottom

    local hovering_now = mouse.x >= edge.left and mouse.x < edge.right and mouse.y >= edge.top and mouse.y < edge.bottom

    sensor.hovering = hovering_now
    sensor.enter = hovering_now and not hovering_before
    sensor.exit = not hovering_now and hovering_before
end

return sensor
