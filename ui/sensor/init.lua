---Sensors are invisible elements that deal with user input.
---The sensor module itself checks for mouse intersections at the end of a frame.
---Overlapping sensors are prioritized from top to bottom with z-ordering.
---Uses screen coordinates.
---For checking mouse buttons, see mouse.lua.
---Sensors are also primitive, they can usedraw queue reservations.
---Sensor updates are also done at the end of the frame instead of during the frame.
---This prevents certain weird bugs caused by combining hovering data from the previous frame with current frame data

--[[
How intersection checking works

The mouse can only interact with:
    - zero or one blocking sensor
    - zero or one lazy sensor
    - zero or more pass sensors
in one frame.

Starting from top to bottom:
- If a blocking sensor is encountered:
    - Check the intersection and stop any further checks below.

- If a lazy sensor is encountered:
    - If there was a previous lazy intersection, cancel it and check this one instead.
    - Continue checking below.
    
- If a pass sensor is encountered:
    - Check the intersection and continue.


- Blocking sensors take priority over all other sensors below them
- The last lazy sensor encountered will be prioritized over all other lazy sensors
- Pass sensor have no priority. They are always checked when encountered.
]]

local mouse = require("ui.mouse")
local extmath = require("ui.extmath")

local sensor = {
    -- If false, disables mouse intersection checks. All hovering fields will become false.
    do_intersections = true,
}

local z_list = {}
local index = 0

---push a sensor to the z-order list
---@param state table
---@param mode "block"|"lazy"|"pass"
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param update_fn? function
function sensor.push(state, mode, left, top, right, bottom, update_fn)
    index = index + 1
    if z_list[index] then
        z_list[index][1], z_list[index][2], z_list[index][3], z_list[index][4], z_list[index][5], z_list[index][6], z_list[index][7] =
            state, mode, left, top, right, bottom, update_fn
    else
        z_list[index] = { state, mode, left, top, right, bottom, update_fn }
    end
end

---Gets run after the draw queue to determine which sensors are hovered by the mouse
function sensor.evaluate()
    local last_lazy_intersection
    -- set to true once a single blocking sensor is found
    local blocked = false

    for i = index, 1, -1 do
        local state = z_list[i][1]

        if sensor.do_intersections and not blocked then
            -- get intersection mode and bounds
            local mode = z_list[i][2]
            local x1, y1, x2, y2 = unpack(z_list[i], 3, 6)

            -- check intersections
            local intersecting_now = extmath.point_in_aligned_rectangle(mouse.screen_x, mouse.screen_y, x1, y1, x2, y2)

            state.hovering = intersecting_now

            if intersecting_now then
                if mode == "lazy" then
                    if last_lazy_intersection then
                        last_lazy_intersection.hovering = false
                    end
                    last_lazy_intersection = state
                elseif mode == "block" then
                    blocked = true
                elseif mode == "pass" then
                    -- pass doesn't actually need to do anything
                else
                    error(string.format("invalid intersection mode `%s`", mode))
                end
            end
        else
            state.hovering = false
        end

        ---update all sensor states
        ---@type function?
        local update_fn = z_list[i][7]
        if update_fn then
            update_fn(state)
        end
    end

    -- restart z_list
    index = 0
end

return sensor
