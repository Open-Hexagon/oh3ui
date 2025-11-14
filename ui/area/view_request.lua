local ep = require("ui.element_parameters")
local stack_data = require("ui.stack_data")
local aeb_stack = stack_data.aeb_stack
local follow = require("ui.effect").follow
local knav = require("ui.control.keyboard_navigation")
local draw_queue = require("ui.draw_queue")
local mnav = require("ui.control.mouse_navigation")
local settings = require("ui.settings")
local theme = require("ui.theme")

local padding = ep.view_request_padding
local base_speed = ep.view_request_speed
local scrollbar_cooldown_time = ep.view_request_scrollbar_cooldown_time

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
local pf_data_size = 11

local just_initiated = false
local view_location_placement_id

---Sets up picture frame data for the view request. This needs to be called while building the draw_queue while inside of a scroll region.
---This function will capture the current state of all relevant scroll regions for the request.
---Only the latest capture is honored.
---@param view_pid integer view location placement id
function view_request.update_auto_scroll(view_pid)
    -- don't do anything if a scroll region isn't active
    if not view_request.top_index then
        return
    end

    if knav.selection_has_changed then
        view_request.time = scrollbar_cooldown_time
        just_initiated = true
    end

    if view_request.time > 0 then
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

        -- mode = VR_START
    end
end

---Adds picture frame data so the view request knows which scroll states to modify
function view_request.add_picture_frame_data(
    state,
    dist_limit_left,
    dist_limit_top,
    dist_limit_right,
    dist_limit_bottom,
    pf_left,
    pf_top,
    pf_right,
    pf_bottom
)
    pf_data_index = pf_data_index + pf_data_size

    -- there are two speed values at -9 and -10 here but they are purposely preserved between frames
    pf_data[pf_data_index - 8] = state
    pf_data[pf_data_index - 7] = dist_limit_left
    pf_data[pf_data_index - 6] = dist_limit_top
    pf_data[pf_data_index - 5] = dist_limit_right
    pf_data[pf_data_index - 4] = dist_limit_bottom
    pf_data[pf_data_index - 3] = pf_left
    pf_data[pf_data_index - 2] = pf_top
    pf_data[pf_data_index - 1] = pf_right
    pf_data[pf_data_index] = pf_bottom
end

local function calculate_speed_heuristic(v_left, v_top, v_right, v_bottom)
    local state
    local dist_limit_left, dist_limit_top, dist_limit_right, dist_limit_bottom
    local pf_left, pf_top, pf_right, pf_bottom
    local move_distance, speed

    for i = pf_data_size, pf_data_index, pf_data_size do
        state = pf_data[i - 8]
        dist_limit_left = pf_data[i - 7]
        dist_limit_top = pf_data[i - 6]
        dist_limit_right = pf_data[i - 5]
        dist_limit_bottom = pf_data[i - 4]
        pf_left = pf_data[i - 3]
        pf_top = pf_data[i - 2]
        pf_right = pf_data[i - 1]
        pf_bottom = pf_data[i]

        -- x movement
        move_distance = 0
        speed = 0
        if v_left < pf_left then
            -- need to scroll left, move_distance is positive
            move_distance = math.min(pf_left - v_left, dist_limit_left - state.scroll_dist_x)
            speed = move_distance * base_speed
        elseif v_right > pf_right then
            -- need to scroll right, move_distance is negative
            move_distance = math.max(pf_right - v_right, dist_limit_right - state.scroll_dist_x)
            speed = move_distance * base_speed
        end
        pf_data[i - 10] = math.abs(speed)
        v_left = v_left + move_distance -- move the requested area for the next iteration
        v_right = v_right + move_distance

        -- y movement
        move_distance = 0
        speed = 0
        if v_top < pf_top then
            -- need to scroll up, move_distance is positive
            move_distance = math.min(pf_top - v_top, dist_limit_top - state.scroll_dist_y)
            speed = move_distance * base_speed
        elseif v_bottom > pf_bottom then
            -- need to scroll down, move_distance is negative
            move_distance = math.max(pf_bottom - v_bottom, dist_limit_bottom - state.scroll_dist_y)
            speed = move_distance * base_speed
        end
        pf_data[i - 9] = math.abs(speed)
        v_top = v_top + move_distance -- move the requested area for the next iteration
        v_bottom = v_bottom + move_distance
    end
end

-- Evaluates view requests. Must be run after the draw queue
function view_request.evaluate()
    if view_request.time == 0 then
        return
    end

    if mnav.holding then
        view_request.time = 0
        just_initiated = false
        pf_data_index = 0
        return
    end

    local view_left, view_top, view_right, view_bottom = draw_queue.get_placement(view_location_placement_id)
    view_left = view_left - padding
    view_top = view_top - padding
    view_right = view_right + padding
    view_bottom = view_bottom + padding

    if just_initiated then
        calculate_speed_heuristic(view_left, view_top, view_right, view_bottom)
    end

    local state
    local pf_left, pf_top, pf_right, pf_bottom
    local move_distance, target
    local x_speed, y_speed

    for i = pf_data_size, pf_data_index, pf_data_size do
        x_speed = pf_data[i - 10]
        y_speed = pf_data[i - 9]
        state = pf_data[i - 8]
        pf_left = pf_data[i - 3]
        pf_top = pf_data[i - 2]
        pf_right = pf_data[i - 1]
        pf_bottom = pf_data[i]

        -- x movement
        target = nil
        if view_left < pf_left then
            -- need to scroll left, move_distance is positive
            move_distance = pf_left - view_left
            target = state.scroll_dist_x + move_distance
        elseif view_right > pf_right then
            -- need to scroll right, move_distance is negative
            move_distance = pf_right - view_right
            target = state.scroll_dist_x + move_distance
        end
        if target then
            state.scroll_dist_x = follow(state.scroll_dist_x, target, x_speed)
        end

        -- y movement
        target = nil
        if view_top < pf_top then
            -- need to scroll up, move_distance is positive
            move_distance = pf_top - view_top
            target = state.scroll_dist_y + move_distance
        elseif view_bottom > pf_bottom then
            -- need to scroll down, move_distance is negative
            move_distance = pf_bottom - view_bottom
            target = state.scroll_dist_y + move_distance
        end
        if target then
            state.scroll_dist_y = follow(state.scroll_dist_y, target, y_speed)
        end
    end

    view_request.time = view_request.time - love.timer.getDelta()

    if view_request.time < 0 then
        view_request.time = 0
    end

    just_initiated = false
    pf_data_index = 0
end

function view_request.update_collapses()
    if not view_request.collapse_top_index then
        return
    end

    local current_index = view_request.collapse_top_index
    if knav.selection_has_changed then
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
