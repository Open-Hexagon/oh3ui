---Sensors are elements that deal with user input.
---They are invisible and never create draw operations.
---The sensor module itself checks for mouse intersections.
---For checking mouse buttons, see mouse.lua.

local edge = require("ui.cursor").edge
local mouse = require("ui.mouse")
local extmath = require("ui.extmath")
local mask = require("ui.mask")

local sensor = {
    -- If false, disables mouse intersection checks. The enter, exit, and hovering fields will always be false.
    do_intersections = true,

    -- * should be read only
    enter = false,
    exit = false,
    hovering = false,
}

---Check and update whether the mouse is intersecting the cursor (i.e. the mouse is hovering the cursor).
---Also detects if the mouse just entered or exited the cursor area.
---Can be disabled by setting `sensor.do_intersections` to false.
---Masked areas are excluded from this check.
---Should be preceded by a `cursor.place()` of some sort.
function sensor.update_mouse_intersect()
    if not sensor.do_intersections then
        sensor.enter = false
        sensor.exit = false
        sensor.hovering = false
        return
    end

    -- exclude masked areas
    local x1, y1, x2, y2 = mask.get_bounds()
    if x1 then
        ---to appease the type checker
        ---@cast x1 number
        ---@cast y1 number
        ---@cast x2 number
        ---@cast y2 number
        x1, y1, x2, y2 =
            extmath.aligned_rectangle_intersection(edge.left, edge.top, edge.right, edge.bottom, x1, y1, x2, y2)

        if not x1 then
            -- no intersection
            sensor.enter = false
            sensor.exit = false
            sensor.hovering = false
            return
        end
    else
        -- no masks
        x1, y1, x2, y2 = edge.left, edge.top, edge.right, edge.bottom
    end

    ---to appease the type checker
    ---@cast x1 number
    ---@cast y1 number
    ---@cast x2 number
    ---@cast y2 number
    local hovering_before = extmath.point_in_aligned_rectangle(mouse.prev_x, mouse.prev_y, x1, y1, x2, y2)
    local hovering_now = extmath.point_in_aligned_rectangle(mouse.x, mouse.y, x1, y1, x2, y2)

    sensor.hovering = hovering_now
    sensor.enter = hovering_now and not hovering_before
    sensor.exit = not hovering_now and hovering_before
end

return sensor
