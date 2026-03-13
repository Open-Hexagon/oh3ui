---Sensors are invisible elements that deal with user input.
---The sensor module itself checks for mouse intersections at the end of a frame.
---Overlapping sensors are prioritized from top to bottom with z-ordering.
---Uses screen coordinates.
---For checking mouse buttons, see mouse.lua.
---Sensor updates are also done at the end of the frame instead of during the frame.
---This prevents certain weird bugs caused by combining hovering data from the previous frame with current frame data

--[[
How intersection checking works

While checking sensors in the z_list in order from top to bottom:
- If there's an intersection then
    - Add its sensor id to the hover_set

    - If the sensor is lazy:
        - If there was a previous lazy intersection, remove it

    - If the sensor is blocking then
        - Stop any further checks

Hovering
- Blocking sensors take priority over all other sensors below them.
- The last lazy sensor encountered will be prioritized over all other lazy sensors.
- Sensors that are neither blocking nor lazy have no priority. They are always counted as hovering.
- A sensor can both be blocking and lazy.

Dragging
- Only one sensor can be dragged at a time
- The sensor that will be dragged will always have previously been in the hover set
- Only sensors flagged as draggable can be dragged
- The lowest (earliest created) sensor will be dragged
]]

local extmath = require("ui.extmath")
local bit = require("bit")
local band = bit.band

local sensor = {
    ---Sensor ids contained in this set are considered being hovered by the cursor
    hover_set = {},

    ---The one sensor id that will be dragged if dragging is initiated
    preemptive_drag_id = nil,

    -- If false, disables mouse intersection checks. The hover set will be empty.
    do_intersections = true,

    -- If this sensor id is set, all other sensor ids behave as if they are disabled.
    -- Gets cleared at the end of the frame so it must be re-asserted every frame.
    exclusive = nil,
}

local hover_set = sensor.hover_set

local z_list = {}
local index = 0
local SIZEOF_Z_ITEM = 6

---Disables checking of intersections. The hover_set will stay empty.
function sensor.disable_intersection_checks()
    sensor.do_intersections = false
end

---Enables checking of intersections. The hover_set is allowed to contain sensor ids.
function sensor.enable_intersection_checks()
    sensor.do_intersections = true
end

---@enum sensor_mode
local sensor_mode = {
    block = 0x1,
    lazy = 0x2,
    draggable = 0x4,
    disable = 0x8, -- sensor cannot be hovered but can still block
}

sensor.sensor_mode = sensor_mode

---push a sensor to the z-order list
---@param sensor_id integer
---@param mode integer
---@param left number
---@param top number
---@param right number
---@param bottom number
function sensor.push(sensor_id, mode, left, top, right, bottom)
    index = index + SIZEOF_Z_ITEM
    z_list[index - 5] = sensor_id
    z_list[index - 4] = mode
    z_list[index - 3] = left
    z_list[index - 2] = top
    z_list[index - 1] = right
    z_list[index] = bottom
end

---Uses the z_list to add sensor ids to update the hover set.
---@param mouse_screen_x integer mouse screen coordinates
---@param mouse_screen_y integer mouse screen coordinates
function sensor.evaluate(mouse_screen_x, mouse_screen_y)
    -- reset state
    for k, _ in pairs(hover_set) do
        hover_set[k] = nil
    end
    sensor.preemptive_drag_id = nil

    if not sensor.do_intersections then
        return
    end

    -- holds the sensor id of the last encountered lazy intersection
    local last_lazy_intersection

    for i = index, 1, -SIZEOF_Z_ITEM do
        -- get sensor id, intersection mode, and bounds
        local sensor_id = z_list[i - 5]
        local mode = z_list[i - 4]
        local x1, y1, x2, y2 = unpack(z_list, i - 3, i)

        -- check intersection, leave immediately if we aren't intersecting
        if not extmath.point_in_aligned_rectangle(mouse_screen_x, mouse_screen_y, x1, y1, x2, y2) then
            goto continue
        end

        -- if exclusive is given but not equal to current sensor_id, do the same thing as the disable flag
        if sensor.exclusive and sensor.exclusive ~= sensor_id then
            goto continue_with_block
        end

        -- skip sensor if it's disabled; we still check if the sensor is blocking
        if band(mode, sensor_mode.disable) ~= 0 then
            goto continue_with_block
        end

        -- add to hover set
        hover_set[sensor_id] = true

        -- do lazy sensor checks
        if band(mode, sensor_mode.lazy) ~= 0 then
            -- remove the last intersection from the hover set and preemptive_drag_id if applicable
            if last_lazy_intersection then
                if last_lazy_intersection == sensor.preemptive_drag_id then
                    sensor.preemptive_drag_id = nil
                end
                hover_set[last_lazy_intersection] = nil
            end
            last_lazy_intersection = sensor_id
        end

        -- Set the preemptive_drag_id if draggable. This overwrites the last drag id
        if band(mode, sensor_mode.draggable) ~= 0 then
            sensor.preemptive_drag_id = sensor_id
        end

        ::continue_with_block::

        if band(mode, sensor_mode.block) ~= 0 then
            -- checking stops if we see a blocking sensor
            break
        end

        ::continue::
    end
end

function sensor.clear()
    index = 0
    sensor.exclusive = nil
end

return sensor
