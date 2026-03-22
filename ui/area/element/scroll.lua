local draw_queue = require("ui.draw_queue")
local cursor = require("ui.cursor")
local projected_placement = cursor.projected_placement
local extmath = require("ui.extmath")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local slot = draw_queue.by_cursor.slot
local rectangle_outline = draw_queue.by_cursor.rectangle_outline
local rectangle_inline = draw_queue.by_cursor.rectangle_inline
local theme = require("ui.theme")
local stack_manager = require("ui.stack_manager")
local aeb = require("ui.area.aeb")
local econf = require("ui.element_conf")
local view_request = require("ui.area.view_request")
local stack_data = require("ui.stack_manager.stack_data")
local aeb_stack = stack_data.aeb_stack
local selection_outline_add_to_queue = require("ui.decorator.element.selection_outline").add_to_queue
local settings = require("ui.settings")

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
---@param scrollbar_inset number? insets the scrollbars away from the scroll region edges
---@param padl number
---@param padt number
---@param padr number
---@param padb number
---@return boolean at_left
---@return boolean at_top
---@return boolean at_right
---@return boolean at_bottom
function scroll.finish(scrollbar_inset, padl, padt, padr, padb)
    scrollbar_inset = scrollbar_inset or 0

    local content_width, content_height, content_left, content_top, content_right, content_bottom
    local scroll_width, scroll_height, scroll_left, scroll_top, scroll_right, scroll_bottom
    local scrollbar_width, scrollbar_height, scrollbar_left, scrollbar_top, scrollbar_right, scrollbar_bottom
    local dist_limit_right, dist_limit_left, dist_limit_bottom, dist_limit_top
    local interacting_with_mouse
    local h_actuator_size, half_h_actuator_size, mouse_limit_left, mouse_limit_right
    local v_actuator_size, half_v_actuator_size, mouse_limit_top, mouse_limit_bottom
    local at_left, at_top, at_right, at_bottom = false, false, false, false
    local vel_decay_factor
    local up_state, hide_scrollbars
    local is_dragging_h_act, is_dragging_v_act, is_dragging_scroll_region

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
    local literal_scroll_left = aeb.pop() + scrollbar_inset
    local literal_scroll_top = aeb.pop() + scrollbar_inset
    local literal_scroll_right = aeb.pop() - scrollbar_inset
    local literal_scroll_bottom = aeb.pop() - scrollbar_inset

    -- get back those sensor ids
    local scroll_region = aeb.pop()
    local scroll_region_wheel_detector = aeb.pop()
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

    cursor.pad(padl, padt, padr, padb)

    if settings.overlay_scroll then
        draw_queue.next_as_overlay()
        rectangle_outline(theme.get_xterm_color(220), 2)
    end

    -- cursor pop (1) happens at the end

    -- element functionality begins here:
    -- peek combine to get the size of the content area (must enclose the original scroll area)
    cursor.combine(true)
    content_width, content_height = cursor.width, cursor.height
    content_left, content_top, content_right, content_bottom = cursor.get_edges()

    -- peek to get the original scroll area size
    cursor.peek()

    if settings.overlay_scroll then
        draw_queue.next_as_overlay()
        rectangle_inline(theme.get_xterm_color(49), 2)
    end

    scroll_width, scroll_height = cursor.width, cursor.height
    scroll_left, scroll_top, scroll_right, scroll_bottom = cursor.get_edges()

    -- get scroll area translation distance limits
    -- should be <= 0 (negative values scroll right)
    dist_limit_right = scroll_right - content_right
    -- should be >= 0 (positive values scroll up)
    dist_limit_left = scroll_left - content_left
    -- should be <= 0 (negative values scroll down)
    dist_limit_bottom = scroll_bottom - content_bottom
    -- should be >= 0 (positive values scroll up)
    dist_limit_top = scroll_top - content_top

    -- scrollbar specific limits
    scrollbar_left = scroll_left + scrollbar_inset
    scrollbar_top = scroll_top + scrollbar_inset
    scrollbar_right = scroll_right - scrollbar_inset
    scrollbar_bottom = scroll_bottom - scrollbar_inset
    scrollbar_width = scrollbar_right - scrollbar_left
    scrollbar_height = scrollbar_bottom - scrollbar_top

    -- clamp before drawing anything because content sizes may have changed since last time
    state.scroll_dist_x = extmath.clamp(state.scroll_dist_x, dist_limit_right, dist_limit_left)
    state.scroll_dist_y = extmath.clamp(state.scroll_dist_y, dist_limit_bottom, dist_limit_top)

    -- If flagged by a view request, export picture frame data
    if flagged_for_view_request then
        view_request.add_picture_frame_data(
            state,
            dist_limit_left,
            dist_limit_top,
            dist_limit_right,
            dist_limit_bottom,
            picture_frame_id
        )
    end

    is_dragging_h_act = mnav.get_dragging(h_act) == mb.left
    is_dragging_v_act = mnav.get_dragging(v_act) == mb.left
    is_dragging_scroll_region = mnav.get_dragging(scroll_region) == mb.left

    interacting_with_mouse = mnav.is_hovering(scroll_region)
        or is_dragging_scroll_region
        or is_dragging_h_act
        or is_dragging_v_act

    hide_scrollbars = not (interacting_with_mouse or view_request.time > 0)

    -- skip scrolling entirely if there's no need
    if content_width <= scroll_width then
        goto horizontal_scrolling_continue
    end

    h_actuator_size = get_actuator_size(content_width, scrollbar_width)

    --#region HORIZONTAL SCROLLING DRAWING

    -- set scrollbar location
    cursor.change_anchor(0, 1)
    cursor.height = scrollbar_thickness + scrollbar_inset

    -- make scroll bar sensor
    -- this is required even if scrollbars are hidden (can cause a brief visual error if not)
    mnav.make_sensor(h_bar, smode.block)

    -- continue if scrollbars are hidden
    if hide_scrollbars then
        goto horizontal_scrolling_continue
    end

    -- set actuator location
    cursor.width = h_actuator_size
    cursor.x = extmath.map(
        state.scroll_dist_x,
        dist_limit_right,
        dist_limit_left,
        scrollbar_right - h_actuator_size,
        scrollbar_left
    )

    cursor.clip_bottom(scrollbar_inset)

    -- make scroll bar actuator sensor
    mnav.make_sensor(h_act, smode.draggable)

    -- shrink the actuator if needed
    if not (mnav.is_hovering(h_bar) or is_dragging_h_act) then
        cursor.height = scrollbar_thickness_inactive
    end

    -- draw the actuator
    slot((is_dragging_h_act or mnav.get_holding(h_act) == mb.left) and theme.grabbed_scrollbar or theme.scrollbar)

    --#endregion HORIZONTAL SCROLLING DRAWING

    -- continue if we're not interacting (this can happen if scrollbars are unhidden by a view request)
    if not interacting_with_mouse then
        goto horizontal_scrolling_continue
    end

    --#region HORIZONTAL SCROLLING INTERACTION

    half_h_actuator_size = h_actuator_size * 0.5

    mouse_limit_left, mouse_limit_right =
        literal_scroll_left + half_h_actuator_size, literal_scroll_right - half_h_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(h_bar) == mb.left and not mnav.is_hovering(h_act) then
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
    if is_dragging_h_act then
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
        if mnav.is_hovering(scroll_region_wheel_detector) and mnav.wheel_dx ~= 0 then
            state.scroll_vel_x = state.scroll_vel_x + mnav.wheel_dx * -mouse_wheel_scroll_sensitivity
        end
    end

    -- scroll if dragging on the scroll region
    if is_dragging_scroll_region then
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

    -- skip scrolling entirely if there's no need
    if content_height <= scroll_height then
        goto vertical_scrolling_continue
    end

    -- peek to get the original scroll area size
    cursor.peek()

    v_actuator_size = get_actuator_size(content_height, scrollbar_height)

    --#region VERTICAL SCROLLING DRAWING

    -- set scrollbar location
    cursor.change_anchor(1, 0)
    cursor.width = scrollbar_thickness + scrollbar_inset

    -- this is required even if scrollbars are hidden (can cause a brief visual error if not)
    mnav.make_sensor(v_bar, smode.block)

    -- continue if scrollbars are hidden
    if hide_scrollbars then
        goto vertical_scrolling_continue
    end

    -- set actuator location
    cursor.height = v_actuator_size
    cursor.y = extmath.map(
        state.scroll_dist_y,
        dist_limit_bottom,
        dist_limit_top,
        scrollbar_bottom - v_actuator_size,
        scrollbar_top
    )

    mnav.make_sensor(v_act, smode.draggable)

    cursor.clip_right(scrollbar_inset)

    -- shrink the actuator if needed
    if not (mnav.is_hovering(v_bar) or is_dragging_v_act) then
        cursor.width = scrollbar_thickness_inactive
    end

    -- draw the actuator
    slot((is_dragging_v_act or mnav.get_holding(v_act) == mb.left) and theme.grabbed_scrollbar or theme.scrollbar)

    --#endregion VERTICAL SCROLLING DRAWING

    -- continue if we're not interacting (this can happen if scrollbars are unhidden by a view request)
    if not interacting_with_mouse then
        goto vertical_scrolling_continue
    end

    --#region VERTICAL SCROLLING INTERACTION

    half_v_actuator_size = v_actuator_size * 0.5

    mouse_limit_top, mouse_limit_bottom =
        literal_scroll_top + half_v_actuator_size, literal_scroll_bottom - half_v_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(v_bar) == mb.left and not mnav.is_hovering(v_act) then
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
    if is_dragging_v_act then
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
        if mnav.is_hovering(scroll_region_wheel_detector) and mnav.wheel_dy ~= 0 then
            state.scroll_vel_y = state.scroll_vel_y + mnav.wheel_dy * mouse_wheel_scroll_sensitivity
        end
    end

    -- scroll if dragging on the scroll region
    if is_dragging_scroll_region then
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

    -- change scroll distances based on velocity

    state.scroll_dist_x = state.scroll_dist_x + state.scroll_vel_x * love.timer.getDelta()
    -- apply limits
    if state.scroll_dist_x < dist_limit_right then
        state.scroll_dist_x = dist_limit_right
        at_right = true -- using this as a temporary value
    elseif state.scroll_dist_x > dist_limit_left then
        state.scroll_dist_x = dist_limit_left
        at_right = true
    end
    -- pass the velocity value up to a higher scroll state so they can scroll if this scroll is at it's limit
    if view_request.top_index and at_right then
        up_state = aeb_stack[view_request.top_index - 1]
        up_state.scroll_vel_x = up_state.scroll_vel_x + state.scroll_vel_x
        state.scroll_vel_x = 0
    end

    -- same as above but for y axis
    state.scroll_dist_y = state.scroll_dist_y + state.scroll_vel_y * love.timer.getDelta()
    if state.scroll_dist_y < dist_limit_bottom then
        state.scroll_dist_y = dist_limit_bottom
        at_bottom = true
    elseif state.scroll_dist_y > dist_limit_top then
        state.scroll_dist_y = dist_limit_top
        at_bottom = true
    end
    if view_request.top_index and at_bottom then
        up_state = aeb_stack[view_request.top_index - 1]
        up_state.scroll_vel_y = up_state.scroll_vel_y + state.scroll_vel_y
        state.scroll_vel_y = 0
    end

    -- decay velocity
    vel_decay_factor = math.min(love.timer.getDelta() * mouse_wheel_scroll_vel_decay, 1)
    state.scroll_vel_x = state.scroll_vel_x - state.scroll_vel_x * vel_decay_factor
    state.scroll_vel_y = state.scroll_vel_y - state.scroll_vel_y * vel_decay_factor

    cursor.peek()

    cursor.edit_translation(tid, state.scroll_dist_x, state.scroll_dist_y)

    -- scroll region sensors are made last so it has the highest priority
    mnav.make_sensor(scroll_region_wheel_detector, smode.lazy)
    -- it takes 1 frame
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

---A special element that marks a location where a view request can be made.
---This element must exist for the full duration of the view request.
---@param activate boolean set this to true for just 1 frame to activate auto scrolling
function scroll.auto_scroll_region(activate)
    cursor.push()
    cursor.auto_area_expansion = "no"
    view_request.update_auto_scroll(draw_queue.by_cursor.blank(), activate)
    cursor.pop()
end

return scroll
