---Sensors are invisible elements that deal with user input.
---The sensor module itself checks for mouse intersections.
---Overlapping sensors are prioritized from bottom to top with z-ordering.
---Uses screen coordinates.
---For checking mouse buttons, see mouse.lua.

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
    -- If false, disables mouse intersection checks. The enter, exit, and hovering fields will always be false.
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
function sensor.push(state, mode, left, top, right, bottom)
    index = index + 1
    if z_list[index] then
        z_list[index][1], z_list[index][2], z_list[index][3], z_list[index][4], z_list[index][5], z_list[index][6] =
            state, mode, left, top, right, bottom
    else
        z_list[index] = { state, mode, left, top, right, bottom }
    end
end

---Gets run after the draw queue to determine which sensors are hovered by the mouse
function sensor.finish()
    if sensor.do_intersections then
        -- after the loop, set to the last encountered lazy intersection for this and the previous frame
        local lazy_now
        local lazy_before
        -- after the loop, set to the last encountered blocking intersection for this and the previous frame
        local blocking_now
        local blocking_before
        -- set to true once a single blocking sensor is found for both before and after intersections
        local now_blocked_flag = false
        local before_blocked_flag = false

        for i = index, 1, -1 do
            local state = z_list[i][1]

            -- get intersection mode and bounds
            local mode = z_list[i][2]
            local x1, y1, x2, y2 = unpack(z_list[i], 3)

            -- check intersections
            -- intersections are forced to be false if they are blocked
            local intersecting_now = extmath.point_in_aligned_rectangle(mouse.screen_x, mouse.screen_y, x1, y1, x2, y2)
                and not now_blocked_flag
            local intersecting_before = extmath.point_in_aligned_rectangle(
                mouse.screen_prev_x,
                mouse.screen_prev_y,
                x1,
                y1,
                x2,
                y2
            ) and not before_blocked_flag

            -- lazy intersections are handled differently
            if mode == "lazy" then
                -- clear lingering enter and exit flags for lazy intersections since the part at the bottom won't (1)
                state.exit = false
                state.enter = false

                -- store references to the state tables of lazy intersections.
                if intersecting_before then
                    lazy_before = state
                end
                if intersecting_now then
                    lazy_now = state
                end
            elseif mode == "block" then
                state.exit = false
                state.enter = false

                -- store references to the state tables of blocking intersections
                if intersecting_before then
                    blocking_before = state
                    before_blocked_flag = true
                end
                if intersecting_now then
                    blocking_now = state
                    now_blocked_flag = true
                end
            elseif mode == "pass" then
                state.hovering = intersecting_now
                state.enter = not intersecting_before and intersecting_now
                state.exit = not intersecting_now and intersecting_before
            else
                error(string.format("invalid intersection mode `%s`", mode))
            end
        end

        -- Do lazy intersections. At least one needs to be found.
        if lazy_now or lazy_before then
            -- if they're different then the mouse just crossed over some boundary
            if lazy_now ~= lazy_before then
                -- one might still be nil
                if lazy_now then
                    lazy_now.hovering = true
                    lazy_now.enter = true
                end
                if lazy_before then
                    lazy_before.hovering = false
                    lazy_before.exit = true
                end
            -- if they're the same, then the mouse is just hovering
            else
                -- hovering should be constantly asserted
                lazy_now.hovering = true
            end
        end

        -- Do blocking intersections. At least one needs to be found.
        if blocking_now or blocking_before then
            -- if they're different then the mouse just crossed over some boundary
            if blocking_now ~= blocking_before then
                if blocking_now then
                    blocking_now.hovering = true
                    blocking_now.enter = true
                end
                if blocking_before then
                    blocking_before.hovering = false
                    blocking_before.exit = true
                end
            -- if they're the same, then the mouse is just hovering
            else
                -- hovering should be constantly asserted
                blocking_now.hovering = true
            end
        end
    else
        -- reset all
        for i = 1, index do
            local state = z_list[i][1]
            state.enter = false
            state.exit = false
            state.hovering = false
        end
    end

    -- restart z_list
    index = 0
end

return sensor
