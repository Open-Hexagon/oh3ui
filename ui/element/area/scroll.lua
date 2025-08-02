local cursor = require("ui.cursor")
local placement = cursor.placement
local extmath = require("ui.extmath")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode
local primitive = require("ui.primitive")
local theme = require("ui.theme")
local effect = require("ui.effect")

local scroll = {}

local scrollbar_thickness = 8
local scrollbar_thickness_inactive = scrollbar_thickness * 0.5
local minimum_scrollbar_actuator_length = 8
local mouse_wheel_scroll_distance = 10
local view_request_padding = scrollbar_thickness * 1.5

local current_state
local scroll_region, h_act, h_bar, v_act, v_bar

---Starts a scroll region
---@param state table
---@return boolean is_viewable True if the scroll area has non-zero area. Can be used to skip evaluating elements inside the scroll region.
function scroll.start(state)
    if cursor.is_degenerate() then
        return false
    end

    if current_state then
        error("nested scrolls are not allowed")
    end

    if not state.initialized then
        state.scroll_dist_x = 0
        state.scroll_dist_y = 0
        state.initialized = true
    end

    -- save the current cursor
    cursor.push()

    -- mask away everything outside of the region
    mask.push()

    -- move the contents of the scroll area
    cursor.apply_translation(
        state.scroll_dist_x, -- positive values scroll left
        state.scroll_dist_y -- positive values scroll up
    )

    current_state = state

    cursor.start_area()

    return true
end

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

---Makes a request for the current scroll region to put the current cursor into view.
---Only the latest made request is honored
function scroll.scroll_into_view()
    -- don't do anything if a scroll region isn't active
    if not current_state then
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

---Horizontal mouse interaction
---@param state table
---@param scroll_limit_left number
---@param scroll_limit_right number
---@param placement_left number
---@param placement_right number
---@param actuator_size number
---@param actuator_left number The left side of the actuator. Not the same as placement_left.
local function do_horizontal_mouse_interaction(
    state,
    scroll_limit_left,
    scroll_limit_right,
    placement_left,
    placement_right,
    actuator_size,
    actuator_left
)
    local half_actuator_size = actuator_size * 0.5

    local mouse_limit_left, mouse_limit_right =
        placement_left + half_actuator_size, placement_right - half_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(h_bar) and not mnav.is_hovering(h_act) then
        state.scroll_dist_x = extmath.map(
            extmath.clamp(mnav.x, mouse_limit_left, mouse_limit_right),
            mouse_limit_left,
            mouse_limit_right,
            scroll_limit_left,
            scroll_limit_right
        )
        cancel_view_request()
    end

    -- move the scrollbar and scroll region if dragging
    if mnav.get_dragging(h_act) then
        if mnav.get_started_dragging(h_act) then
            state._mouse_offset_x = mnav.press_x - (actuator_left + half_actuator_size)
        end
        state.scroll_dist_x = extmath.map(
            extmath.clamp(mnav.x - state._mouse_offset_x, mouse_limit_left, mouse_limit_right),
            mouse_limit_left,
            mouse_limit_right,
            scroll_limit_left,
            scroll_limit_right
        )
        cancel_view_request()
    else
        -- mouse wheel (disabled if dragging)
        if mnav.wheel_dx ~= 0 then
            state.scroll_dist_x = extmath.clamp(
                state.scroll_dist_x + mnav.wheel_dx * -mouse_wheel_scroll_distance,
                scroll_limit_right,
                scroll_limit_left
            )
            cancel_view_request()
        end
    end

    -- scroll if dragging on the scroll region
    if mnav.get_dragging(scroll_region) then
        if mnav.get_started_dragging(scroll_region) then
            state._mouse_offset_x = mnav.press_x - state.scroll_dist_x
        end
        state.scroll_dist_x = extmath.clamp(mnav.x - state._mouse_offset_x, scroll_limit_right, scroll_limit_left)
        cancel_view_request()
    end

    state.at_left = state.scroll_dist_x == scroll_limit_left
    state.at_right = state.scroll_dist_x == scroll_limit_right
end

---Vertical mouse interaction
---@param state table
---@param scroll_limit_top number
---@param scroll_limit_bottom number
---@param placement_top number
---@param placement_bottom number
---@param actuator_size number
---@param actuator_top number The top of the actuator. Not the same as placement_top.
local function do_vertical_mouse_interaction(
    state,
    scroll_limit_top,
    scroll_limit_bottom,
    placement_top,
    placement_bottom,
    actuator_size,
    actuator_top
)
    local half_actuator_size = actuator_size * 0.5

    local mouse_limit_top, mouse_limit_bottom =
        placement_top + half_actuator_size, placement_bottom - half_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(v_bar) and not mnav.is_hovering(v_act) then
        state.scroll_dist_y = extmath.map(
            extmath.clamp(mnav.y, mouse_limit_top, mouse_limit_bottom),
            mouse_limit_top,
            mouse_limit_bottom,
            scroll_limit_top,
            scroll_limit_bottom
        )
        cancel_view_request()
    end

    -- move the scrollbar and region if dragging
    if mnav.get_dragging(v_act) then
        if mnav.get_started_dragging(v_act) then
            state._mouse_offset_y = (mnav.press_y - (actuator_top + half_actuator_size))
        end
        state.scroll_dist_y = extmath.map(
            extmath.clamp(mnav.y - state._mouse_offset_y, mouse_limit_top, mouse_limit_bottom),
            mouse_limit_top,
            mouse_limit_bottom,
            scroll_limit_top,
            scroll_limit_bottom
        )
        cancel_view_request()
    else
        -- mouse wheel (disabled if dragging)
        if mnav.wheel_dy ~= 0 then
            state.scroll_dist_y = extmath.clamp(
                state.scroll_dist_y + mnav.wheel_dy * mouse_wheel_scroll_distance,
                scroll_limit_bottom,
                scroll_limit_top
            )
            cancel_view_request()
        end
    end

    -- scroll if dragging on the scroll region
    if mnav.get_dragging(scroll_region) then
        if mnav.get_started_dragging(scroll_region) then
            state._mouse_offset_y = mnav.press_y - state.scroll_dist_y
        end
        state.scroll_dist_y = extmath.clamp(mnav.y - state._mouse_offset_y, scroll_limit_bottom, scroll_limit_top)
        cancel_view_request()
    end

    state.at_top = state.scroll_dist_y == scroll_limit_top
    state.at_bottom = state.scroll_dist_y == scroll_limit_bottom
end

local function get_actuator_size(content_size, scroll_size)
    return math.max(scroll_size * scroll_size / content_size, minimum_scrollbar_actuator_length)
end

---Finishes the current scroll region
---@param state table This must be the same table as the coresponding scroll.start
---@param padding number scroll area padding
function scroll.finish(state, padding)
    if not current_state then
        error("scroll.finish called with no active scroll")
    end

    cursor.finish_area()
    cursor.outset(padding)

    mask.pop()
    cursor.remove_translation()

    scroll_region = mnav.declare_sensor_id()
    h_act = mnav.declare_sensor_id()
    h_bar = mnav.declare_sensor_id()
    v_act = mnav.declare_sensor_id()
    v_bar = mnav.declare_sensor_id()

    -- peek combine to get the size of the content area (must enclose the original scroll area)
    cursor.combine(true)
    local content_width, content_height = cursor.width, cursor.height
    local content_left, content_top, content_right, content_bottom = cursor.ltrb()

    -- peek to get the original scroll area size
    cursor.peek()
    local scroll_width, scroll_height = cursor.width, cursor.height

    -- get scroll area translation limits
    local scroll_left, scroll_top, scroll_right, scroll_bottom = cursor.ltrb()

    -- should be <= 0 (negative values scroll right)
    local scroll_limit_right = scroll_right - content_right
    -- should be >= 0 (positive values scroll up)
    local scroll_limit_left = scroll_left - content_left
    -- should be <= 0 (negative values scroll down)
    local scroll_limit_bottom = scroll_bottom - content_bottom
    -- should be >= 0 (positive values scroll up)
    local scroll_limit_top = scroll_top - content_top

    -- actuator sizes
    local h_actuator_size = get_actuator_size(content_width, scroll_width)
    local v_actuator_size = get_actuator_size(content_height, scroll_height)

    -- need to place to get literal cursor location for mouse limits
    cursor.place()
    local placement_left, placement_top, placement_right, placement_bottom =
        placement.left, placement.top, placement.right, placement.bottom

    local possibly_interacting = mnav.is_hovering(scroll_region)
        or mnav.get_dragging(scroll_region)
        or mnav.get_dragging(h_act)
        or mnav.get_dragging(v_act)

    if possibly_interacting or view_request.show_sb_cooldown > 0 then
        if content_width > scroll_width then
            -- set scrollbar location
            cursor.change_anchor(0, 1)
            cursor.height = scrollbar_thickness

            mnav.make_sensor(h_bar, smode.block)

            -- set actuator location
            cursor.width = h_actuator_size
            cursor.x = extmath.map(
                state.scroll_dist_x,
                scroll_limit_right,
                scroll_limit_left,
                scroll_right - h_actuator_size,
                scroll_left
            )

            mnav.make_sensor(h_act, smode.draggable)

            -- shrink the actuator if needed
            if not (mnav.is_hovering(h_bar) or mnav.get_dragging(h_act)) then
                cursor.height = scrollbar_thickness_inactive
            end

            -- draw the actuator
            primitive.slot(
                (mnav.get_dragging(h_act) or mnav.get_holding(h_act)) and theme.grabbed_scrollbar or theme.scrollbar
            )

            if possibly_interacting then
                do_horizontal_mouse_interaction(
                    state,
                    scroll_limit_left,
                    scroll_limit_right,
                    placement_left,
                    placement_right,
                    h_actuator_size,
                    placement.left
                )
            end
        end

        if content_height > scroll_height then
            cursor.peek()

            -- set scrollbar location
            cursor.change_anchor(1, 0)
            cursor.width = scrollbar_thickness

            mnav.make_sensor(v_bar, smode.block)

            -- set actuator location
            cursor.height = v_actuator_size
            cursor.y = extmath.map(
                state.scroll_dist_y,
                scroll_limit_bottom,
                scroll_limit_top,
                scroll_bottom - v_actuator_size,
                scroll_top
            )

            mnav.make_sensor(v_act, smode.draggable)

            -- shrink the actuator if needed
            if not (mnav.is_hovering(v_bar) or mnav.get_dragging(v_act)) then
                cursor.width = scrollbar_thickness_inactive
            end

            -- draw the actuator
            primitive.slot(
                (mnav.get_dragging(v_act) or mnav.get_holding(v_act)) and theme.grabbed_scrollbar or theme.scrollbar
            )

            if possibly_interacting then
                do_vertical_mouse_interaction(
                    state,
                    scroll_limit_top,
                    scroll_limit_bottom,
                    placement_top,
                    placement_bottom,
                    v_actuator_size,
                    placement.top
                )
            end
        end
    end

    cursor.pop()

    do_view_request(
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

    mnav.make_sensor(scroll_region, smode.lazy, smode.draggable)

    current_state = nil
end

return scroll
