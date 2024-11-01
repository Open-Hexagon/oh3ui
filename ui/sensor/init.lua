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

local z_list = {}
local index = 0

function sensor.push(state, left, top, right, bottom)
    index = index + 1
    if z_list[index] then
        z_list[index][1], z_list[index][2], z_list[index][3], z_list[index][4], z_list[index][5] =
            state, left, top, right, bottom
    else
        z_list[index] = { state, left, top, right, bottom }
    end
end

function sensor.finish()
    -- state table of the sensor being hovered this frame
    local hovering_now

    for i = index, 1, -1 do
        local state = z_list[i][1]

        -- reset these fields
        state.enter = false
        state.exit = false

        -- set hovering to false except for the topmost intersection
        if not hovering_now and extmath.point_in_aligned_rectangle(mouse.x, mouse.y, unpack(z_list[i], 2)) then
            state.hovering = true
            hovering_now = state
        else
            state.hovering = false
        end
    end

    -- state table of the sensor being hovered last frame
    local hovering_before
    for i = index, 1, -1 do
        local state = z_list[i][1]
        if extmath.point_in_aligned_rectangle(mouse.prev_x, mouse.prev_y, unpack(z_list[i], 2)) then
            hovering_before = state
            break
        end
    end

    -- set enter and exit fields
    if hovering_now ~= hovering_before then
        if hovering_now then
            hovering_now.enter = true
        end
        if hovering_before then
            hovering_before.exit = true
        end
    end

    -- restart z_list
    index = 0
end

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
