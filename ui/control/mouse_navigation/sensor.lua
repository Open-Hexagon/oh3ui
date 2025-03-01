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

The mouse can only interact with:
    - zero or one blocking sensor
    - zero or one lazy sensor
    - zero or more pass sensors
in one frame.

Checking sensors in the z_list in order from top to bottom:
- If there's an intersection and the sensor is a...
    - Blocking sensor:
        - Add its sensor id to the hover_set.
        - Stop any further checks below.

    - Lazy sensor:
        - If there was a previous lazy intersection, remove it from the hover_set.
        - Add the new sensor id to the hover_set and continue.
        
    - Pass sensor:
        - Add its sensor id to the hover_set and continue.


- Blocking sensors take priority over all other sensors below them.
- The last lazy sensor encountered will be prioritized over all other lazy sensors.
- Pass sensors have no priority.
]]

local extmath = require("ui.extmath")

local sensor = {
    ---Sensor ids contained in this set are considered being hovered by the cursor
    hover_set = {},
}

-- If false, disables mouse intersection checks. All hovering fields will become false.
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

---push a sensor to the z-order list
---@param sensor_id integer
---@param mode "block"|"lazy"|"pass"
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
    -- empty the hover set
    for k, _ in pairs(hover_set) do
        hover_set[k] = nil
    end

    if do_intersections then
        -- holds the sensor id of the last encountered lazy intersection
        local last_lazy_intersection

        for i = index, 1, -1 do
            -- get sensor id, intersection mode, and bounds
            local sensor_id = z_list[i][1]
            local mode = z_list[i][2]
            local x1, y1, x2, y2 = unpack(z_list[i], 3, 6)

            -- check intersection
            if extmath.point_in_aligned_rectangle(mouse_screen_x, mouse_screen_y, x1, y1, x2, y2) then
                -- add to hover set
                hover_set[sensor_id] = true

                if mode == "lazy" then
                    if last_lazy_intersection then
                        -- remove the last intersection from the hover set
                        hover_set[last_lazy_intersection] = nil
                    end
                    last_lazy_intersection = sensor_id
                elseif mode == "block" then
                    -- checking stops if we see a blocking sensor
                    break
                elseif mode == "pass" then
                    -- pass doesn't actually need to do anything
                else
                    error(string.format("invalid intersection mode `%s`", mode))
                end
            end
        end
    end

    -- restart z_list
    index = 0
end

return sensor
