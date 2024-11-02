---Sensors are invisible elements that deal with user input.
---The sensor module itself checks for mouse intersections.
---Overlapping sensors are prioritized from top to bottom with z-ordering.
---For checking mouse buttons, see mouse.lua.

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
---@param mode "block"|"pass"
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
        -- set to true once a single blocking sensor is found
        local blocked = false
        for i = index, 1, -1 do
            local state = z_list[i][1]

            if blocked then
                state.enter = false
                state.exit = false
                state.hovering = false
            else
                local x1, y1, x2, y2 = unpack(z_list[i], 3)
                local hovering_now = extmath.point_in_aligned_rectangle(mouse.screen_x, mouse.screen_y, x1, y1, x2, y2)
                local hovering_before =
                    extmath.point_in_aligned_rectangle(mouse.screen_prev_x, mouse.screen_prev_y, x1, y1, x2, y2)

                state.enter = hovering_now and not hovering_before
                state.exit = not hovering_now and hovering_before
                state.hovering = hovering_now

                if hovering_now then
                    local mode = z_list[i][2]
                    if mode == "block" then
                        blocked = true
                    elseif mode == "pass" then
                    else
                        error("invalid sensor mode")
                    end
                end
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
