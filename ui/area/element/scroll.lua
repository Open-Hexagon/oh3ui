local cursor = require("ui.cursor")
local projected_placement = cursor.projected_placement
local placement = cursor.placement
local extmath = require("extmath")
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode
local slot = require("ui.draw_queue").by_cursor.slot
local theme = require("ui.theme")
local stack_manager = require("ui.stack_manager")
local aeb = require("ui.area.aeb")
local econf = require("ui.element_conf")
local view_request = require("ui.area.view_request")
local stack_data = require("ui.stack_manager.stack_data")
local selection_outline_add_to_queue = require("ui.decorator.element.selection_outline").add_to_queue
local draw_queue = require("ui.draw_queue")
local draw_data_add_draw_operation = require("ui.draw_queue.draw_data").add_draw_operation
local view_request_export_picture_frame = require("ui.draw_queue.draw_operation").view_request_export_picture_frame

local scroll = {}

local scrollbar_thickness = econf.scrollbar_thickness
local scrollbar_thickness_inactive = econf.scrollbar_thickness_inactive
local minimum_scrollbar_actuator_length = econf.minimum_scrollbar_actuator_length
local mouse_wheel_scroll_sensitivity = econf.mouse_wheel_scroll_sensitivity
local mouse_wheel_scroll_vel_decay = econf.mouse_wheel_scroll_vel_decay

--[[
    +--------+CCCCCCC <-- Content region surrounds all
    |        |''''''C
    | Scroll |''''''C 
    | Region |------+
    |        |      |
    +--------+      |
    C''''|   Area   |
    C''''|  Region  |
    CCCCC+----------+

    Scroll region:
    This is the region that is saved when you call scroll.start().
    It is the viewable window into what the scroll element contains.
    The scroll bars are placed in here.

    Area region:
    This is the region that surrounds all elements created inside the scroll region.
    This region may be padded before it gets used.

    Content region:
    This region is the entire area that the scroll region can view.
    It is the smallest rectangle that surrounds both the scroll region and area region.
]]

---Starts a scroll region
---@param state table
function scroll.start(state)
    if not state.initialized then
        state.scroll_dist_x = 0
        state.scroll_dist_y = 0
        state.scroll_vel_x = 0
        state.scroll_vel_y = 0
        state.initialized = true
    end

    -- save the current cursor
    cursor.push() -- (1)

    -- mask away everything outside of the region
    -- ! this has to come before push_translation!
    local picture_frame_id = draw_queue.by_cursor.push_mask() -- (2)

    -- move the contents of the scroll area
    local tid = cursor.push_translation(
        state.scroll_dist_x, -- positive values scroll left
        state.scroll_dist_y -- positive values scroll up
    ) -- (3)

    -- for use later
    cursor.start_area() -- (4)

    -- save picture frame placement id in case of view request
    aeb.push(picture_frame_id)

    -- save transform id
    aeb.push(tid)

    -- make a bunch of sensor ids (order does not matter)
    aeb.push(mnav.declare_sensor_id())
    aeb.push(mnav.declare_sensor_id())
    aeb.push(mnav.declare_sensor_id())
    aeb.push(mnav.declare_sensor_id())
    aeb.push(mnav.declare_sensor_id())

    -- save literal cursor position for use later
    aeb.push(projected_placement.bottom)
    aeb.push(projected_placement.right)
    aeb.push(projected_placement.top)
    aeb.push(projected_placement.left)

    aeb.push(false) -- this gets turned into a true if a view request was made
    aeb.push(state) -- state
    aeb.push(view_request.top_index) -- aeb_index of the next (up) state
    view_request.top_index = stack_data.aeb_index -- put the new view request top index

    aeb.push_frame_header("scroll") -- (5)

    -- lock all stacks after we've done setup
    stack_manager.push_record() -- (6)
end

local mouse_offset_x
local mouse_offset_y

local function get_actuator_size(content_size, scroll_size)
    return math.max(scroll_size * scroll_size / content_size, minimum_scrollbar_actuator_length)
end
---Finishes the current scroll region
---@param padding number scroll area padding
---@return boolean at_left
---@return boolean at_top
---@return boolean at_right
---@return boolean at_bottom
function scroll.finish(padding)
    local content_width, content_height, content_left, content_top, content_right, content_bottom
    local scroll_width, scroll_height, scroll_left, scroll_top, scroll_right, scroll_bottom
    local dist_limit_right, dist_limit_left, dist_limit_bottom, dist_limit_top
    local interacting_with_mouse
    local h_actuator_size, half_h_actuator_size, mouse_limit_left, mouse_limit_right
    local v_actuator_size, half_v_actuator_size, mouse_limit_top, mouse_limit_bottom
    local at_left, at_top, at_right, at_bottom = false, false, false, false
    local vel_decay_factor

    -- deal with stack stuff
    stack_manager.pop_record() -- (6)

    -- Must come before pop_mask so the selection outline appears inside the scroll region
    -- Must come before cursor.remove_translation so the scroll request is made in the correct location
    selection_outline_add_to_queue()

    aeb.pop_frame_header("scroll") -- (5)

    view_request.top_index = aeb.pop() -- revert the view request top index
    local state = aeb.pop() -- get the state back
    local flagged_for_view_request = aeb.pop() -- get whether we're flagged for a view request

    -- get back literal scroll area for mouse limits
    local literal_scroll_left = aeb.pop()
    local literal_scroll_top = aeb.pop()
    local literal_scroll_right = aeb.pop()
    local literal_scroll_bottom = aeb.pop()

    -- get back those sensor ids
    local scroll_region = aeb.pop()
    local h_act = aeb.pop()
    local h_bar = aeb.pop()
    local v_act = aeb.pop()
    local v_bar = aeb.pop()

    local tid = aeb.pop()
    local picture_frame_id = aeb.pop()

    cursor.pop_translation() -- (3)
    draw_queue.pop_mask() -- (2)

    if not cursor.finish_area(true) then -- (4)
        goto scroll_is_empty
    end

    cursor.outset(padding)

    -- cursor pop (1) happens at the end

    -- element functionality begins here:
    -- peek combine to get the size of the content area (must enclose the original scroll area)
    cursor.combine(true)
    content_width, content_height = cursor.width, cursor.height
    content_left, content_top, content_right, content_bottom = cursor.ltrb()

    -- peek to get the original scroll area size
    cursor.peek()
    scroll_width, scroll_height = cursor.width, cursor.height
    scroll_left, scroll_top, scroll_right, scroll_bottom = cursor.ltrb()

    -- get scroll area translation distance limits
    -- should be <= 0 (negative values scroll right)
    dist_limit_right = scroll_right - content_right
    -- should be >= 0 (positive values scroll up)
    dist_limit_left = scroll_left - content_left
    -- should be <= 0 (negative values scroll down)
    dist_limit_bottom = scroll_bottom - content_bottom
    -- should be >= 0 (positive values scroll up)
    dist_limit_top = scroll_top - content_top

    -- clamp before drawing anything because content sizes may have changed since last time
    state.scroll_dist_x = extmath.clamp(state.scroll_dist_x, dist_limit_right, dist_limit_left)
    state.scroll_dist_y = extmath.clamp(state.scroll_dist_y, dist_limit_bottom, dist_limit_top)

    -- If flagged by a view request, export picture frame data
    if flagged_for_view_request then
        draw_data_add_draw_operation(
            view_request_export_picture_frame,
            state,
            dist_limit_left,
            dist_limit_top,
            dist_limit_right,
            dist_limit_bottom,
            picture_frame_id
        )
    end

    interacting_with_mouse = mnav.is_hovering(scroll_region)
        or mnav.get_dragging(scroll_region)
        or mnav.get_dragging(h_act)
        or mnav.get_dragging(v_act)

    if not (interacting_with_mouse or view_request.time > 0) then
        goto skip_all_scrolling
    end

    if content_width <= scroll_width then
        goto horizontal_scrolling_continue
    end

    h_actuator_size = get_actuator_size(content_width, scroll_width)

    --#region HORIZONTAL SCROLLING DRAWING

    -- set scrollbar location
    cursor.change_anchor(0, 1)
    cursor.height = scrollbar_thickness

    -- make scroll bar sensor
    mnav.make_sensor(h_bar, smode.block)

    -- set actuator location
    cursor.width = h_actuator_size
    cursor.x =
        extmath.map(state.scroll_dist_x, dist_limit_right, dist_limit_left, scroll_right - h_actuator_size, scroll_left)

    -- make scroll bar actuator sensor
    mnav.make_sensor(h_act, smode.draggable)

    -- shrink the actuator if needed
    if not (mnav.is_hovering(h_bar) or mnav.get_dragging(h_act)) then
        cursor.height = scrollbar_thickness_inactive
    end

    -- draw the actuator
    slot((mnav.get_dragging(h_act) or mnav.get_holding(h_act)) and theme.grabbed_scrollbar or theme.scrollbar)

    --#endregion HORIZONTAL SCROLLING DRAWING

    if not interacting_with_mouse then
        goto horizontal_scrolling_continue
    end

    --#region HORIZONTAL SCROLLING INTERACTION

    half_h_actuator_size = h_actuator_size * 0.5

    mouse_limit_left, mouse_limit_right =
        literal_scroll_left + half_h_actuator_size, literal_scroll_right - half_h_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(h_bar) and not mnav.is_hovering(h_act) then
        state.scroll_vel_x = 0
        state.scroll_dist_x = extmath.map(
            extmath.clamp(mnav.x, mouse_limit_left, mouse_limit_right),
            mouse_limit_left,
            mouse_limit_right,
            dist_limit_left,
            dist_limit_right
        )
    end

    -- move the scrollbar and scroll region if dragging
    if mnav.get_dragging(h_act) then
        state.scroll_vel_x = 0
        if mnav.get_started_dragging(h_act) then
            mouse_offset_x = mnav.press_x - (projected_placement.left + half_h_actuator_size)
        end
        state.scroll_dist_x = extmath.map(
            extmath.clamp(mnav.x - mouse_offset_x, mouse_limit_left, mouse_limit_right),
            mouse_limit_left,
            mouse_limit_right,
            dist_limit_left,
            dist_limit_right
        )
    else
        -- mouse wheel (disabled if dragging)
        if mnav.wheel_dx ~= 0 then
            state.scroll_vel_x = state.scroll_vel_x + mnav.wheel_dx * -mouse_wheel_scroll_sensitivity
        end
    end

    -- scroll if dragging on the scroll region
    if mnav.get_dragging(scroll_region) then
        state.scroll_vel_x = 0
        if mnav.get_started_dragging(scroll_region) then
            mouse_offset_x = mnav.press_x - state.scroll_dist_x
        end
        state.scroll_dist_x = mnav.x - mouse_offset_x
    end
    -- letting go while moving while dragging the scroll region sets the velocity so the scroll coasts
    if mnav.get_stopped_dragging(scroll_region) then
        state.scroll_vel_x = mnav.dx
    end

    --#endregion HORIZONTAL SCROLLING INTERACTION

    ::horizontal_scrolling_continue::

    if content_height <= scroll_height then
        goto vertical_scrolling_continue
    end

    -- peek to get the original scroll area size
    cursor.peek()

    v_actuator_size = get_actuator_size(content_height, scroll_height)

    --#region VERTICAL SCROLLING DRAWING

    -- set scrollbar location
    cursor.change_anchor(1, 0)
    cursor.width = scrollbar_thickness

    mnav.make_sensor(v_bar, smode.block)

    -- set actuator location
    cursor.height = v_actuator_size
    cursor.y =
        extmath.map(state.scroll_dist_y, dist_limit_bottom, dist_limit_top, scroll_bottom - v_actuator_size, scroll_top)

    mnav.make_sensor(v_act, smode.draggable)

    -- shrink the actuator if needed
    if not (mnav.is_hovering(v_bar) or mnav.get_dragging(v_act)) then
        cursor.width = scrollbar_thickness_inactive
    end

    -- draw the actuator
    slot((mnav.get_dragging(v_act) or mnav.get_holding(v_act)) and theme.grabbed_scrollbar or theme.scrollbar)

    --#endregion VERTICAL SCROLLING DRAWING

    if not interacting_with_mouse then
        goto vertical_scrolling_continue
    end

    --#region VERTICAL SCROLLING INTERACTION

    half_v_actuator_size = v_actuator_size * 0.5

    mouse_limit_top, mouse_limit_bottom =
        literal_scroll_top + half_v_actuator_size, literal_scroll_bottom - half_v_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(v_bar) and not mnav.is_hovering(v_act) then
        state.scroll_vel_y = 0
        state.scroll_dist_y = extmath.map(
            extmath.clamp(mnav.y, mouse_limit_top, mouse_limit_bottom),
            mouse_limit_top,
            mouse_limit_bottom,
            dist_limit_top,
            dist_limit_bottom
        )
    end

    -- move the scrollbar and region if dragging
    if mnav.get_dragging(v_act) then
        state.scroll_vel_y = 0
        if mnav.get_started_dragging(v_act) then
            mouse_offset_y = (mnav.press_y - (projected_placement.top + half_v_actuator_size))
        end
        state.scroll_dist_y = extmath.map(
            extmath.clamp(mnav.y - mouse_offset_y, mouse_limit_top, mouse_limit_bottom),
            mouse_limit_top,
            mouse_limit_bottom,
            dist_limit_top,
            dist_limit_bottom
        )
    else
        -- mouse wheel (disabled if dragging)
        if mnav.wheel_dy ~= 0 then
            state.scroll_vel_y = state.scroll_vel_y + mnav.wheel_dy * mouse_wheel_scroll_sensitivity
        end
    end

    -- scroll if dragging on the scroll region
    if mnav.get_dragging(scroll_region) then
        state.scroll_vel_y = 0
        if mnav.get_started_dragging(scroll_region) then
            mouse_offset_y = mnav.press_y - state.scroll_dist_y
        end
        state.scroll_dist_y = mnav.y - mouse_offset_y
    end
    -- letting go while moving while dragging the scroll region sets the velocity so the scroll coasts
    if mnav.get_stopped_dragging(scroll_region) then
        state.scroll_vel_y = mnav.dy
    end

    --#endregion VERTICAL SCROLLING INTERACTION

    ::vertical_scrolling_continue::

    ::skip_all_scrolling::

    -- edit scroll distances
    state.scroll_dist_x = extmath.clamp(
        state.scroll_dist_x + state.scroll_vel_x * love.timer.getDelta(),
        dist_limit_right,
        dist_limit_left
    )

    state.scroll_dist_y = extmath.clamp(
        state.scroll_dist_y + state.scroll_vel_y * love.timer.getDelta(),
        dist_limit_bottom,
        dist_limit_top
    )

    -- decay velocity
    vel_decay_factor = math.min(love.timer.getDelta() * mouse_wheel_scroll_vel_decay, 1)
    state.scroll_vel_x = state.scroll_vel_x - state.scroll_vel_x * vel_decay_factor
    state.scroll_vel_y = state.scroll_vel_y - state.scroll_vel_y * vel_decay_factor

    cursor.peek()

    cursor.edit_translation(tid, state.scroll_dist_x, state.scroll_dist_y)

    -- scroll region sensor is made last so it has the highest priority
    mnav.make_sensor(scroll_region, smode.draggable)

    -- these values are true if the scroll region is at the content limits
    at_left = state.scroll_dist_x == dist_limit_left
    at_top = state.scroll_dist_y == dist_limit_top
    at_right = state.scroll_dist_x == dist_limit_right
    at_bottom = state.scroll_dist_y == dist_limit_bottom

    ::scroll_is_empty::

    cursor.pop() -- (1)

    return at_left, at_top, at_right, at_bottom
end

return scroll
