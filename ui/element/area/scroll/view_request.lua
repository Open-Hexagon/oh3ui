local cursor = require("ui.cursor")
local placement = cursor.placement
local area_element = require("ui.element.area")
local volatile_data = require("ui.shared_data").volatile
local aeb_stack = volatile_data.aeb_stack
local follow = require("ui.effect").follow

local view_request_padding = area_element.view_request_padding
local view_request_speed = area_element.view_request_speed
local view_request_cooldown = area_element.view_request_scrollbar_cooldown_time

local view_request = {
    -- The index of the top state
    -- This is kept updated by the scroll elements
    top_index = nil,
    time = 0,
}

local VR_IDLE, VR_START, VR_RUNNING = 0, 1, 2
local mode = VR_IDLE

local running_states = {}
local picture_frames = { 0, 0, 0, 0 } -- left, top, right, bottom
local ts_data = { 0, 0, 0, 0 } -- x_target, x_speed, y_target, y_speed
local running_states_index = 0

local dist_limits = { 0, 0, 0, 0 } -- left, top, right, bottom
local dist_limits_index = 0

local left, top, right, bottom

local function calculate_request_parameters()
    local move_distance, target, speed
    local i4, pf_left, pf_top, pf_right, pf_bottom
    local state

    for i = 1, running_states_index do
        state = running_states[i]
        i4 = i * 4

        pf_left = picture_frames[i4 - 3]
        pf_top = picture_frames[i4 - 2]
        pf_right = picture_frames[i4 - 1]
        pf_bottom = picture_frames[i4]

        -- x movement
        move_distance = 0
        ts_data[i4 - 3] = nil -- erase old values
        ts_data[i4 - 2] = nil
        if left < pf_left then
            -- need to scroll left, move_distance is positive
            move_distance = pf_left - left
            target = math.min(state.scroll_dist_x + move_distance, dist_limits[i4 - 3])
            speed = (target - state.scroll_dist_x) * view_request_speed

            ts_data[i4 - 3] = target
            ts_data[i4 - 2] = speed
        elseif right > pf_right then
            -- need to scroll right, move_distance is negative
            move_distance = pf_right - right
            target = math.max(state.scroll_dist_x + move_distance, dist_limits[i4 - 1])
            speed = (state.scroll_dist_x - target) * view_request_speed

            ts_data[i4 - 3] = target
            ts_data[i4 - 2] = speed
        end
        left = left + move_distance -- move the requested area for the next iteration
        right = right + move_distance

        -- y movement
        move_distance = 0
        ts_data[i4 - 1] = nil -- erase old values
        ts_data[i4] = nil
        if top < pf_top then
            -- need to scroll up, move_distance is positive
            move_distance = pf_top - top
            target = math.min(state.scroll_dist_y + move_distance, dist_limits[i4 - 2])
            speed = (target - state.scroll_dist_y) * view_request_speed

            ts_data[i4 - 1] = target
            ts_data[i4] = speed
        elseif bottom > pf_bottom then
            -- need to scroll down, move_distance is negative
            move_distance = pf_bottom - bottom
            target = math.max(state.scroll_dist_y + move_distance, dist_limits[i4])
            speed = (state.scroll_dist_y - target) * view_request_speed

            ts_data[i4 - 1] = target
            ts_data[i4] = speed
        end
        top = top + move_distance -- move the requested area for the next iteration
        bottom = bottom + move_distance
    end
end

---Makes a request for the current scroll region to put the current cursor into view.
---Only the latest made request is honored
function view_request.scroll_into_view()
    -- don't do anything if a scroll region isn't active
    if not view_request.top_index then
        return
    end

    running_states_index = 0
    dist_limits_index = 0

    cursor.area_expansion_off()
    cursor.place()
    cursor.area_expansion_on()

    -- get the requested area
    left = placement.left - view_request_padding
    top = placement.top - view_request_padding
    right = placement.right + view_request_padding
    bottom = placement.bottom + view_request_padding

    -- copy all states that will be affected by the request
    local current_index = view_request.top_index
    local pf_index
    while current_index do
        running_states_index = running_states_index + 1
        running_states[running_states_index] = aeb_stack[current_index - 1]
        aeb_stack[current_index - 2] = true -- flag this state as requested

        pf_index = running_states_index * 4
        picture_frames[pf_index - 3] = aeb_stack[current_index - 3] -- left
        picture_frames[pf_index - 2] = aeb_stack[current_index - 4] -- top
        picture_frames[pf_index - 1] = aeb_stack[current_index - 5] -- right
        picture_frames[pf_index] = aeb_stack[current_index - 6] -- bottom

        -- next state index
        current_index = aeb_stack[current_index]
    end

    mode = VR_START
    view_request.time = view_request_cooldown
end

function view_request.push_limits(dist_limit_left, dist_limit_top, dist_limit_right, dist_limit_bottom)
    dist_limits_index = dist_limits_index + 4
    dist_limits[dist_limits_index - 3] = dist_limit_left
    dist_limits[dist_limits_index - 2] = dist_limit_top
    dist_limits[dist_limits_index - 1] = dist_limit_right
    dist_limits[dist_limits_index] = dist_limit_bottom
end

function view_request.cancel()
    mode = VR_IDLE
    view_request.time = 0
end

function view_request.evaluate()
    if mode == VR_IDLE then
        return
    end

    if mode == VR_START then
        calculate_request_parameters()
        mode = VR_RUNNING
    end

    local i4, state, x_target, y_target
    for i = 1, running_states_index do
        state = running_states[i]
        i4 = i * 4

        x_target = ts_data[i4 - 3]
        if x_target then
            state.scroll_dist_x = follow(state.scroll_dist_x, x_target, ts_data[i4 - 2])
            if state.scroll_dist_x == x_target then
                ts_data[i4 - 3] = nil
            end
        end

        y_target = ts_data[i4 - 1]
        if y_target then
            state.scroll_dist_y = follow(state.scroll_dist_y, y_target, ts_data[i4])
            if state.scroll_dist_y == y_target then
                ts_data[i4 - 1] = nil
            end
        end
    end

    view_request.time = view_request.time - love.timer.getDelta()

    if view_request.time <= 0 then
        view_request.cancel()
    end
end

return view_request
