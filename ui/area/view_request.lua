local econf = require("ui.element_conf")
local stack_data = require("ui.stack_manager.stack_data")
local aeb_stack = stack_data.aeb_stack
local follow = require("ui.effect").follow
local draw_queue = require("ui.draw_queue")
local knav = require("ui.control.keyboard_navigation")
local settings = require("ui.settings")
local theme = require("ui.theme")
local extmath = require("ui.extmath")

local padding = econf.view_request_padding
local base_speed = econf.view_request_speed
local scrollbar_cooldown_time = econf.view_request_scrollbar_cooldown_time

local view_request = {
    -- The index of the top state
    -- This is kept updated by the scroll elements
    top_index = nil,

    -- Time remaining for view request. If greater than 0, view request is enabled
    time = 0,

    -- The index of the top collapse state
    collapse_top_index = nil,
}

local pf_data = {}
local pf_data_index = 0
local pf_data_size = 12

local just_initiated = false
local view_location_placement_id
local current_auto_scroll_id
local auto_scroll_id = 0

---Sets up picture frame data for the view request.
---This needs to be called every frame during the view request while building the draw_queue while inside of a scroll region.
---This function will capture the current state of all relevant scroll regions for the request.
---Only the latest capture is honored.
---@param view_pid integer view location placement id
---@param activate boolean set this to true for just 1 frame to activate auto scrolling
function view_request.update_auto_scroll(view_pid, activate)
    -- don't do anything if a scroll region isn't active
    if not view_request.top_index then
        return
    end

    auto_scroll_id = auto_scroll_id + 1

    if activate then
        view_request.time = scrollbar_cooldown_time
        just_initiated = true
        current_auto_scroll_id = auto_scroll_id
    end

    if view_request.time > 0 and auto_scroll_id == current_auto_scroll_id then
        view_location_placement_id = view_pid

        if settings.overlay_view_request then
            draw_queue.next_as_overlay()
            draw_queue.by_id.rectangle_inline(view_pid, 2, 0, 0, unpack(theme.get_xterm_color(75)))

            -- copy placement for outer outline that shows padding
            local left, top, right, bottom = draw_queue.get_placement(view_pid)
            local pid = draw_queue.make_placement(left - padding, top - padding, right + padding, bottom + padding)

            draw_queue.next_as_overlay()
            draw_queue.by_id.rectangle_outline(pid, 2, 0, 0, unpack(theme.get_xterm_color(203)))
        end

        -- flag all above scroll areas as requested
        local current_index = view_request.top_index
        while current_index do
            aeb_stack[current_index - 2] = true -- flag this state as requested

            -- next state index
            current_index = aeb_stack[current_index]
        end
    end
end

---Adds picture frame data so the view request knows which scroll states to modify
function view_request.add_picture_frame_data(
    state,
    dist_limit_left,
    dist_limit_top,
    dist_limit_right,
    dist_limit_bottom,
    pf_placement_id
)
    pf_data_index = pf_data_index + pf_data_size

    -- there are two target values at -8 and -9
    -- there are two speed values at -6 and -7
    -- there are more values past -5 that are purposely preserved between frames
    pf_data[pf_data_index - 5] = state
    pf_data[pf_data_index - 4] = dist_limit_left
    pf_data[pf_data_index - 3] = dist_limit_top
    pf_data[pf_data_index - 2] = dist_limit_right
    pf_data[pf_data_index - 1] = dist_limit_bottom
    pf_data[pf_data_index] = pf_placement_id
end

local function calculate_speeds_and_targets(v_left, v_top, v_right, v_bottom)
    local state
    local dist_limit_left, dist_limit_top, dist_limit_right, dist_limit_bottom
    local pf_left, pf_top, pf_right, pf_bottom, pf_width, pf_height
    local move_distance, speed, target
    local v_width = v_right - v_left
    local v_height = v_bottom - v_top

    for i = pf_data_size, pf_data_index, pf_data_size do
        state = pf_data[i - 5]
        dist_limit_left = pf_data[i - 4]
        dist_limit_top = pf_data[i - 3]
        dist_limit_right = pf_data[i - 2]
        dist_limit_bottom = pf_data[i - 1]
        pf_left, pf_top, pf_right, pf_bottom = draw_queue.get_placement(pf_data[i])
        pf_width = pf_right - pf_left
        pf_height = pf_bottom - pf_top

        -- x movement
        move_distance = 0
        speed = 0
        target = nil
        if v_width >= pf_width or v_left < pf_left then
            -- this is forced if the view is bigger than the pf to always prioritize the left edge
            -- need to scroll left, move_distance is positive
            move_distance = pf_left - v_left
        elseif v_right > pf_right then
            -- need to scroll right, move_distance is negative
            move_distance = pf_right - v_right
        end
        if move_distance ~= 0 then
            target = extmath.clamp(state.scroll_dist_x + move_distance, dist_limit_right, dist_limit_left)
            move_distance = target - state.scroll_dist_y
            speed = math.abs(move_distance * base_speed)
        end
        pf_data[i - 11] = state.scroll_dist_x
        pf_data[i - 9] = target
        pf_data[i - 7] = speed
        state.scroll_vel_x = 0 -- stop the scroll from moving by other means
        v_left = v_left + move_distance -- move the requested area for the next iteration
        v_right = v_right + move_distance

        -- y movement
        move_distance = 0
        speed = 0
        target = nil
        if v_height >= pf_height or v_top < pf_top then
            -- this is forced if the view is bigger than the pf to always prioritize the top edge
            -- need to scroll up, move_distance is positive
            move_distance = pf_top - v_top
        elseif v_bottom > pf_bottom then
            -- need to scroll down, move_distance is negative
            move_distance = pf_bottom - v_bottom
        end
        if move_distance ~= 0 then
            target = extmath.clamp(state.scroll_dist_y + move_distance, dist_limit_bottom, dist_limit_top)
            move_distance = target - state.scroll_dist_y
            speed = math.abs(move_distance * base_speed)
        end
        pf_data[i - 10] = state.scroll_dist_y
        pf_data[i - 8] = target
        pf_data[i - 6] = speed
        state.scroll_vel_y = 0 -- stop the scroll from moving by other means
        v_top = v_top + move_distance -- move the requested area for the next iteration
        v_bottom = v_bottom + move_distance
    end
end

-- Evaluates view requests. Must be run after the draw queue
function view_request.evaluate()
    auto_scroll_id = 0

    if view_request.time == 0 then
        return
    end

    local view_left, view_top, view_right, view_bottom = draw_queue.get_placement(view_location_placement_id)
    view_left = view_left - padding
    view_top = view_top - padding
    view_right = view_right + padding
    view_bottom = view_bottom + padding

    if just_initiated then
        calculate_speeds_and_targets(view_left, view_top, view_right, view_bottom)
    end

    local state
    local x_speed, y_speed, x_target, y_target, last_scroll_dist_x, last_scroll_dist_y

    for i = pf_data_size, pf_data_index, pf_data_size do
        last_scroll_dist_x = pf_data[i - 11]
        last_scroll_dist_y = pf_data[i - 10]
        x_target = pf_data[i - 9]
        y_target = pf_data[i - 8]
        x_speed = pf_data[i - 7]
        y_speed = pf_data[i - 6]
        state = pf_data[i - 5]

        -- x movement
        -- Check against the last scroll distance. Any outside changes to the scroll distance will break the view request.
        if last_scroll_dist_x ~= state.scroll_dist_x then
            view_request.time = 0
            goto movement_break
        end
        if x_target then
            state.scroll_dist_x = follow(state.scroll_dist_x, x_target, x_speed)
            pf_data[i - 11] = state.scroll_dist_x
            if state.scroll_dist_x == x_target then
                pf_data[i - 9] = nil
            end
        end

        -- y movement
        if last_scroll_dist_y ~= state.scroll_dist_y then
            view_request.time = 0
            goto movement_break
        end
        if y_target then
            state.scroll_dist_y = follow(state.scroll_dist_y, y_target, y_speed)
            pf_data[i - 10] = state.scroll_dist_y
            if state.scroll_dist_y == y_target then
                pf_data[i - 8] = nil
            end
        end
    end

    view_request.time = view_request.time - love.timer.getDelta()

    if view_request.time < 0 then
        view_request.time = 0
    end

    ::movement_break::

    just_initiated = false
    pf_data_index = 0
end

function view_request.update_collapses()
    if not view_request.collapse_top_index then
        return
    end

    local current_index = view_request.collapse_top_index
    if knav.has_selection_just_changed() then
        while current_index do
            aeb_stack[current_index - 1] = true -- set the "contains selection" field
            aeb_stack[current_index - 2] = true -- set the "selection has changed" field
            current_index = aeb_stack[current_index]
        end
    else
        while current_index do
            aeb_stack[current_index - 1] = true -- set the "contains selection" field
            current_index = aeb_stack[current_index]
        end
    end
end

return view_request
