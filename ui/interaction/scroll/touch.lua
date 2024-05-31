local events = require("ui.event_queue")
local state = require("ui.state")
local area = require("ui.area")

---give control over the scrolling to a finger
---@param scroll_state table
---@param finger lightuserdata
local function give_scroll_control(scroll_state, finger)
    local data = area.get_extra_data()

    local x, y = love.touch.getPosition(finger)
    -- save the absolute position including the height of hidden scroll content
    if data.direction == "vertical" then
        scroll_state.area_grabbed_at = y + scroll_state.position
    else -- data.direction == "horizontal"
        scroll_state.area_grabbed_at = x + scroll_state.position
    end

    scroll_state.current_finger = finger
end

---remove all fingers that are no longer active from fingers table
---@param scroll_state table
---@return boolean  true if the current finger was removed
local function clean_up_finger_list(scroll_state)
    local removed_current = false
    local active_touches = love.touch.getTouches()
    for i = #scroll_state.fingers, 1, -1 do
        local is_active = false
        for j = 1, #active_touches do
            if active_touches[j] == scroll_state.fingers[i] then
                is_active = true
                break
            end
        end
        if not is_active then
            if scroll_state.fingers[i] == scroll_state.current_finger then
                removed_current = true
            end
            table.remove(scroll_state.fingers, i)
        end
    end
    return removed_current
end

---handle touch scroll interaction
---@param scroll_state table
return function(scroll_state)
    -- don't process touch scroll if scrollbar is grabbed
    if scroll_state.scrollbar_grabbed_at then
        return
    end

    -- finger ids sorted by scrolling priority (latest touch is more important)
    scroll_state.fingers = scroll_state.fingers or {}

    -- handle events
    for event in events.iterate("touch.*") do
        local name = event[1]

        -- grab scroll area when putting a finger down
        -- only the latest finger is used for scrolling
        if name == "touchpressed" then
            local x, y = event[3], event[4]
            if area.is_position_inside(x, y, true) and state.is_position_interactable(x, y) then
                give_scroll_control(scroll_state, event[2])
                scroll_state.fingers[#scroll_state.fingers + 1] = scroll_state.current_finger
            end
        end
    end

    -- remove released touches
    if clean_up_finger_list(scroll_state) then
        -- current finger was removed
        local finger_count = #scroll_state.fingers
        if finger_count == 0 then
            -- no fingers are pressed anymore
            scroll_state.area_grabbed_at = nil
            scroll_state.current_finger = nil
            scroll_state.finger_pressure = scroll_state.finger_pressure or 1
            local new_pos = scroll_state.position + scroll_state.last_delta * 40 * scroll_state.finger_pressure
            require("ui.interaction.scroll").go_to(new_pos, 0.3, "out_sine")
        else
            -- other finger/s are still held down
            -- TODO: short scroll velocity that is stopped by other finger
            give_scroll_control(scroll_state, scroll_state.fingers[finger_count])
        end
    end

    if scroll_state.area_grabbed_at and scroll_state.current_finger then
        -- store pressure for later use in velocity calculation
        scroll_state.finger_pressure = love.touch.getPressure(scroll_state.current_finger)
        local x, y = love.touch.getPosition(scroll_state.current_finger)

        local scroll_position = 0
        local data = area.get_extra_data()

        -- calculating scroll position like so:
        -- (subtracting delta as moving finger down (positive delta) should result in moving scroll up (negative delta))
        --  scroll_pos = start_scroll_pos - (current_coord - first_coord)
        --  scroll_pos = start_scroll_pos - current_coord + first_coord
        --  scroll_pos = start_scroll_pos + first_coord - current_coord
        --   this was set in the event handler earlier: area_grabbed_at = first_coord + start_scroll_pos
        --  scroll_pos = area_grabbed_at - current_coord
        if data.direction == "vertical" then
            scroll_position = scroll_state.area_grabbed_at - y
        else -- data.direction == "horizontal"
            scroll_position = scroll_state.area_grabbed_at - x
        end

        require("ui.interaction.scroll").go_to(scroll_position, 0, "none")
    end
end
