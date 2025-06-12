---Sensors are invisible elements that deal with user input.
---The sensor module itself checks for mouse intersections at the end of a frame.
---Overlapping sensors are prioritized from top to bottom with z-ordering.
---Uses screen coordinates.
---For checking mouse buttons, see mouse.lua.
---Sensors are also primitive, they can use draw queue reservations.
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
- The sensor that will be dragged will always be previously in the hover set
- The sensor that is picked uses the same rules of hovering but only within the hover set
- When determining which sensor will be dragged
    - All sensors by default behave as if they were lazy (this is cannot be turned off)
    - Sensors can be spedified to be blocking (using the dblock flag instead of block)
]]

local extmath = require("ui.extmath")
local bit = require("bit")
local band = bit.band

local sensor = {
    ---Sensor ids contained in this set are considered being hovered by the cursor
    hover_set = {},

    ---The one sensor id that will be dragged if dragging is initiated
    preemptive_drag_id = nil,
}

-- If false, disables mouse intersection checks. The hover set will be empty.
local do_intersections = true

local hover_set = sensor.hover_set

local z_list = {}
local index = 0

---Disables checking of intersections. The hover_set will stay empty.
function sensor.disable_intersection_checks()
    do_intersections = false
end

---Enables checking of intersections. The hover_set is allowed to contain sensor ids.
function sensor.enable_intersection_checks()
    do_intersections = true
end

local sensor_mode = {
    block = 0x1,
    lazy = 0x2,
    dblock = 0x4,
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
    index = index + 1
    if z_list[index] then
        z_list[index][1], z_list[index][2], z_list[index][3], z_list[index][4], z_list[index][5], z_list[index][6] =
            sensor_id, mode, left, top, right, bottom
    else
        z_list[index] = { sensor_id, mode, left, top, right, bottom }
    end
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

    if do_intersections then
        -- holds the sensor id of the last encountered lazy intersection
        local last_lazy_intersection
        local dragging_blocked = false

        for i = index, 1, -1 do
            -- get sensor id, intersection mode, and bounds
            local sensor_id = z_list[i][1]
            local mode = z_list[i][2]
            local x1, y1, x2, y2 = unpack(z_list[i], 3, 6)

            -- check intersection
            if extmath.point_in_aligned_rectangle(mouse_screen_x, mouse_screen_y, x1, y1, x2, y2) then
                -- add to hover set
                hover_set[sensor_id] = true

                if not dragging_blocked then
                    -- Set the preemptive_drag_id. This overwrites the last drag id
                    sensor.preemptive_drag_id = sensor_id
                    if band(mode, sensor_mode.dblock) ~= 0 then
                        dragging_blocked = true
                    end
                end

                if band(mode, sensor_mode.lazy) ~= 0 then
                    if last_lazy_intersection then
                        -- remove the last intersection from the hover set
                        hover_set[last_lazy_intersection] = nil
                    end
                    last_lazy_intersection = sensor_id
                end

                if band(mode, sensor_mode.block) ~= 0 then
                    -- checking stops if we see a blocking sensor
                    break
                end
            end
        end
    end

    -- restart z_list
    index = 0
end

return sensor
