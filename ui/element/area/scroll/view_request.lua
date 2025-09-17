local cursor = require("ui.cursor")
local placement = cursor.placement
local area_element = require("ui.element.area")

local view_request_padding = area_element.view_request_padding
local view_request_speed = area_element.view_request_speed

local view_request = {
    top_state = nil, -- the scroll region we are currently in
    time = 0,
}

-- TODO Remove the use of _up since it gets rewritten every frame
-- TODO We have to make a copy the chain of scroll states or else we're going to fumble the states 

local current_request = {
    _up = nil,
    _literal_scroll_left = nil,
    _literal_scroll_top = nil,
    _literal_scroll_right = nil,
    _literal_scroll_bottom = nil,
}

-- TODO don't do this chaining thing, just use the original view requested area all the time but just move it between iterations

local function calculate_request_parameters(state)
    local move_distance, target, speed, rq_left, rq_top, rq_right, rq_bottom, pf_left, pf_top, pf_right, pf_bottom

    local requester = state
    local picture_frame = requester._up
    while picture_frame do
        rq_left, rq_top, rq_right, rq_bottom =
            requester._literal_scroll_left,
            requester._literal_scroll_top,
            requester._literal_scroll_right,
            requester._literal_scroll_bottom

        pf_left, pf_top, pf_right, pf_bottom =
            picture_frame._literal_scroll_left,
            picture_frame._literal_scroll_top,
            picture_frame._literal_scroll_right,
            picture_frame._literal_scroll_bottom

        if rq_left < pf_left then
            -- need to scroll left
            move_distance = pf_left - rq_left
            target = math.min(picture_frame.scroll_dist_x + move_distance, picture_frame._dist_limit_left)
            speed = (target - picture_frame.scroll_dist_x) * view_request_speed

            picture_frame._x_target = target
            picture_frame._x_speed = speed
        elseif rq_right > pf_right then
            -- need to scroll right
            move_distance = rq_right - pf_right
            target = math.max(picture_frame.scroll_dist_x - move_distance, picture_frame._dist_limit_right)
            speed = (picture_frame.scroll_dist_x - target) * view_request_speed

            picture_frame._x_target = target
            picture_frame._x_speed = speed
        end

        if rq_top < pf_top then
            -- need to scroll up
            move_distance = pf_top - rq_top
            target = math.min(picture_frame.scroll_dist_y + move_distance, picture_frame._dist_limit_top)
            speed = (target - picture_frame.scroll_dist_y) * view_request_speed

            picture_frame._y_target = target
            picture_frame._y_speed = speed
        elseif rq_bottom > pf_bottom then
            -- need to scroll down
            move_distance = rq_bottom - pf_bottom
            target = math.max(picture_frame.scroll_dist_y - move_distance, picture_frame._dist_limit_bottom)
            speed = (picture_frame.scroll_dist_y - target) * view_request_speed

            picture_frame._y_target = target
            picture_frame._y_speed = speed
        end

        picture_frame._view_request_flag = true

        picture_frame = requester._up
    end
end

---Makes a request for the current scroll region to put the current cursor into view.
---Only the latest made request is honored
function view_request.scroll_into_view()
    -- don't do anything if a scroll region isn't active
    if not view_request.top_state then
        return
    end

    current_request._up = view_request.top_state

    cursor.area_expansion_off()
    cursor.place()
    cursor.area_expansion_on()

    current_request._literal_scroll_left = placement.left - view_request_padding
    current_request._literal_scroll_top = placement.top - view_request_padding
    current_request._literal_scroll_right = placement.right + view_request_padding
    current_request._literal_scroll_bottom = placement.bottom + view_request_padding

    -- TODO this cannot be run at the moment the request was made since the distance limits have not been calculated yet!
    calculate_request_parameters(current_request)

    view_request.time = 1.5
end

function view_request.cancel() end

function view_request.evaluate() end

--[[

--#region view request

local view_request_speed = 10

local VR_IDLE, VR_START, VR_RUNNING = 0, 1, 2

local view_request = {
    mode = VR_IDLE,

    x_speed = nil,
    x_target = nil,
    y_speed = nil,
    y_target = nil,

    left = nil,
    top = nil,
    right = nil,
    bottom = nil,

    show_sb_cooldown = 0,
}


function scroll.scroll_into_view()
    -- don't do anything if a scroll region isn't active
    if not top_state then
        return
    end

    cursor.area_expansion_off()
    cursor.place()
    cursor.area_expansion_on()

    view_request.left = placement.left - view_request_padding
    view_request.top = placement.top - view_request_padding
    view_request.right = placement.right + view_request_padding
    view_request.bottom = placement.bottom + view_request_padding

    view_request.mode = VR_START
end

local function cancel_view_request()
    view_request.mode = VR_IDLE
    view_request.show_sb_cooldown = 0
end

---Move the scroll area for a view request
---@param state table
---@param placement_left number
---@param placement_top number
---@param placement_right number
---@param placement_bottom number
local function do_view_request(
    state,
    placement_left,
    placement_top,
    placement_right,
    placement_bottom,
    scroll_limit_left,
    scroll_limit_top,
    scroll_limit_right,
    scroll_limit_bottom
)
    if view_request.mode == VR_IDLE then
        return
    end

    if view_request.mode == VR_START then
        local move_distance

        if view_request.left < placement_left then
            -- need to scroll left
            move_distance = placement_left - view_request.left
            view_request.x_target = math.min(state.scroll_dist_x + move_distance, scroll_limit_left)
            view_request.x_speed = (view_request.x_target - state.scroll_dist_x) * view_request_speed
        elseif view_request.right > placement_right then
            -- need to scroll right
            move_distance = view_request.right - placement_right
            view_request.x_target = math.max(state.scroll_dist_x - move_distance, scroll_limit_right)
            view_request.x_speed = (state.scroll_dist_x - view_request.x_target) * view_request_speed
        end

        if view_request.top < placement_top then
            -- need to scroll up
            move_distance = placement_top - view_request.top
            view_request.y_target = math.min(state.scroll_dist_y + move_distance, scroll_limit_top)
            view_request.y_speed = (view_request.y_target - state.scroll_dist_y) * view_request_speed
        elseif view_request.bottom > placement_bottom then
            -- need to scroll down
            move_distance = view_request.bottom - placement_bottom
            view_request.y_target = math.max(state.scroll_dist_y - move_distance, scroll_limit_bottom)
            view_request.y_speed = (state.scroll_dist_y - view_request.y_target) * view_request_speed
        end

        view_request.show_sb_cooldown = 1.5

        view_request.mode = VR_RUNNING
    end

    if view_request.x_target then
        state.scroll_dist_x = effect.follow(state.scroll_dist_x, view_request.x_target, view_request.x_speed)
        if state.scroll_dist_x == view_request.x_target then
            view_request.x_target = nil
        end
    end

    if view_request.y_target then
        state.scroll_dist_y = effect.follow(state.scroll_dist_y, view_request.y_target, view_request.y_speed)
        if state.scroll_dist_y == view_request.y_target then
            view_request.y_target = nil
        end
    end

    view_request.show_sb_cooldown = view_request.show_sb_cooldown - love.timer.getDelta()

    if view_request.show_sb_cooldown <= 0 then
        cancel_view_request()
    end
end

--#endregion

]]

return view_request
