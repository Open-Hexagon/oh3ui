local cursor = require("ui.cursor")
local projected_placement = cursor.projected_placement
local extmath = require("ui.extmath")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode
local primitive = require("ui.primitive")
local theme = require("ui.theme")
local stack_manager = require("ui.stack_manager")
local area_element = require("ui.area")
local view_request = require("ui.area.view_request")
local volatile_data = require("ui.shared_data").volatile
local selection_outline = require("ui.decorator.selection_outline")
local draw_data_edit_translation = require("ui.draw_queue.draw_data").edit_translation

local scroll = {}

local scrollbar_thickness = area_element.scrollbar_thickness
local scrollbar_thickness_inactive = area_element.scrollbar_thickness_inactive
local minimum_scrollbar_actuator_length = area_element.minimum_scrollbar_actuator_length
local mouse_wheel_scroll_distance = area_element.mouse_wheel_scroll_distance

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
        state.initialized = true
    end

    -- save the current cursor
    cursor.push() -- (1)
    cursor.place() -- ! this has to come before apply_translation!

    -- mask away everything outside of the region
    mask.push() -- (2)

    -- move the contents of the scroll area
    local tid = cursor.push_translation(
        state.scroll_dist_x, -- positive values scroll left
        state.scroll_dist_y -- positive values scroll up
    ) -- (3)

    -- for use later
    cursor.start_area() -- (4)

    -- save transform id
    area_element.aeb_push(tid)

    -- make a bunch of sensor ids (order does not matter)
    area_element.aeb_push(mnav.declare_sensor_id())
    area_element.aeb_push(mnav.declare_sensor_id())
    area_element.aeb_push(mnav.declare_sensor_id())
    area_element.aeb_push(mnav.declare_sensor_id())
    area_element.aeb_push(mnav.declare_sensor_id())

    -- save literal cursor position for use later
    area_element.aeb_push(projected_placement.bottom)
    area_element.aeb_push(projected_placement.right)
    area_element.aeb_push(projected_placement.top)
    area_element.aeb_push(projected_placement.left)

    area_element.aeb_push(false) -- this gets turned into a true if a view request was made
    area_element.aeb_push(state) -- state
    area_element.aeb_push(view_request.top_index) -- aeb_index of the next (up) state
    view_request.top_index = volatile_data.aeb_index -- put the new view request top index

    area_element.aeb_push_frame_header("scroll") -- (5)

    -- lock all stacks after we've done setup
    stack_manager.push_record() -- (6)
end

local mouse_offset_x
local mouse_offset_y

---Horizontal mouse interaction
---@param state table
---@param dist_limit_left number left scroll translation limit
---@param dist_limit_right number right scroll translation limit
---@param literal_scroll_left number literal position of the left side of the scroll region
---@param literal_scroll_right number literal position of the right side of the scroll region
---@param actuator_width number width of the actuator
---@param literal_actuator_left number literal position of the left side of the actuator
---@param scroll_region integer sensor id of the scroll region
---@param h_bar integer sensor id of the horizontal scroll bar
---@param h_act integer sensor_id of the horizontal scroll actuator
local function do_horizontal_mouse_interaction(
    state,
    dist_limit_left,
    dist_limit_right,
    literal_scroll_left,
    literal_scroll_right,
    actuator_width,
    literal_actuator_left,
    scroll_region,
    h_bar,
    h_act
)
    local half_actuator_width = actuator_width * 0.5

    local mouse_limit_left, mouse_limit_right =
        literal_scroll_left + half_actuator_width, literal_scroll_right - half_actuator_width

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(h_bar) and not mnav.is_hovering(h_act) then
        state.scroll_dist_x = extmath.map(
            extmath.clamp(mnav.x, mouse_limit_left, mouse_limit_right),
            mouse_limit_left,
            mouse_limit_right,
            dist_limit_left,
            dist_limit_right
        )
        view_request.cancel()
    end

    -- move the scrollbar and scroll region if dragging
    if mnav.get_dragging(h_act) then
        if mnav.get_started_dragging(h_act) then
            mouse_offset_x = mnav.press_x - (literal_actuator_left + half_actuator_width)
        end
        state.scroll_dist_x = extmath.map(
            extmath.clamp(mnav.x - mouse_offset_x, mouse_limit_left, mouse_limit_right),
            mouse_limit_left,
            mouse_limit_right,
            dist_limit_left,
            dist_limit_right
        )
        view_request.cancel()
    else
        -- mouse wheel (disabled if dragging)
        if mnav.wheel_dx ~= 0 then
            state.scroll_dist_x = state.scroll_dist_x + mnav.wheel_dx * -mouse_wheel_scroll_distance
            view_request.cancel()
        end
    end

    -- scroll if dragging on the scroll region
    if mnav.get_dragging(scroll_region) then
        if mnav.get_started_dragging(scroll_region) then
            mouse_offset_x = mnav.press_x - state.scroll_dist_x
        end
        state.scroll_dist_x = mnav.x - mouse_offset_x
        view_request.cancel()
    end
end

---Vertical mouse interaction
---@param state table
---@param dist_limit_top number top scroll translation limit
---@param dist_limit_bottom number bottom scroll translation limit
---@param literal_scroll_top number literal position of the top side of the scroll region
---@param literal_scroll_bottom number literal position of the bottom side of the scroll region
---@param actuator_height number height of the actuator
---@param literal_actuator_top number literal position of the top side of the actuator
---@param scroll_region integer sensor id of the scroll region
---@param v_bar integer sensor id of the vertical scroll bar
---@param v_act integer sensor_id of the vertical scroll actuator
local function do_vertical_mouse_interaction(
    state,
    dist_limit_top,
    dist_limit_bottom,
    literal_scroll_top,
    literal_scroll_bottom,
    actuator_height,
    literal_actuator_top,
    scroll_region,
    v_bar,
    v_act
)
    local half_actuator_size = actuator_height * 0.5

    local mouse_limit_top, mouse_limit_bottom =
        literal_scroll_top + half_actuator_size, literal_scroll_bottom - half_actuator_size

    -- goto location if the bar is held outside of the actuator
    if mnav.get_holding(v_bar) and not mnav.is_hovering(v_act) then
        state.scroll_dist_y = extmath.map(
            extmath.clamp(mnav.y, mouse_limit_top, mouse_limit_bottom),
            mouse_limit_top,
            mouse_limit_bottom,
            dist_limit_top,
            dist_limit_bottom
        )
        view_request.cancel()
    end

    -- move the scrollbar and region if dragging
    if mnav.get_dragging(v_act) then
        if mnav.get_started_dragging(v_act) then
            mouse_offset_y = (mnav.press_y - (literal_actuator_top + half_actuator_size))
        end
        state.scroll_dist_y = extmath.map(
            extmath.clamp(mnav.y - mouse_offset_y, mouse_limit_top, mouse_limit_bottom),
            mouse_limit_top,
            mouse_limit_bottom,
            dist_limit_top,
            dist_limit_bottom
        )
        view_request.cancel()
    else
        -- mouse wheel (disabled if dragging)
        if mnav.wheel_dy ~= 0 then
            state.scroll_dist_y = state.scroll_dist_y + mnav.wheel_dy * mouse_wheel_scroll_distance
            view_request.cancel()
        end
    end

    -- scroll if dragging on the scroll region
    if mnav.get_dragging(scroll_region) then
        if mnav.get_started_dragging(scroll_region) then
            mouse_offset_y = mnav.press_y - state.scroll_dist_y
        end
        state.scroll_dist_y = mnav.y - mouse_offset_y
        view_request.cancel()
    end
end

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
    -- deal with stack stuff
    stack_manager.pop_record() -- (6)

    -- Must come before mask.pop so the selection outline appears inside the scroll region
    -- Must come before cursor.remove_translation so the scroll request is made in the correct location
    selection_outline.add_to_queue()

    area_element.aeb_pop_frame_header("scroll") -- (5)

    view_request.top_index = area_element.aeb_pop() -- revert the view request top index
    local state = area_element.aeb_pop() -- get the state back
    local flagged_for_view_request = area_element.aeb_pop() -- get whether we're flagged for a view request

    -- get back literal scroll area for mouse limits
    local literal_scroll_left = area_element.aeb_pop()
    local literal_scroll_top = area_element.aeb_pop()
    local literal_scroll_right = area_element.aeb_pop()
    local literal_scroll_bottom = area_element.aeb_pop()

    -- get back those sensor ids
    local scroll_region = area_element.aeb_pop()
    local h_act = area_element.aeb_pop()
    local h_bar = area_element.aeb_pop()
    local v_act = area_element.aeb_pop()
    local v_bar = area_element.aeb_pop()

    local tid = area_element.aeb_pop()

    cursor.pop_translation() -- (3)
    mask.pop() -- (2)

    if not cursor.finish_area(true) then -- (4)
        -- scroll region is empty
        cursor.pop() -- (1)
        return false, false, false, false
    end

    cursor.outset(padding)

    -- cursor pop (1) happens later

    -- element functionality begins here:
    -- peek combine to get the size of the content area (must enclose the original scroll area)
    cursor.combine(true)
    local content_width, content_height = cursor.width, cursor.height
    local content_left, content_top, content_right, content_bottom = cursor.ltrb()

    -- peek to get the original scroll area size
    cursor.peek()
    local scroll_width, scroll_height = cursor.width, cursor.height
    local scroll_left, scroll_top, scroll_right, scroll_bottom = cursor.ltrb()

    -- get scroll area translation distance limits
    -- should be <= 0 (negative values scroll right)
    local dist_limit_right = scroll_right - content_right
    -- should be >= 0 (positive values scroll up)
    local dist_limit_left = scroll_left - content_left
    -- should be <= 0 (negative values scroll down)
    local dist_limit_bottom = scroll_bottom - content_bottom
    -- should be >= 0 (positive values scroll up)
    local dist_limit_top = scroll_top - content_top

    -- These are needed by view requests
    if flagged_for_view_request then
        view_request.push_limits(dist_limit_left, dist_limit_top, dist_limit_right, dist_limit_bottom)
    end

    state.scroll_dist_x = extmath.clamp(state.scroll_dist_x, dist_limit_right, dist_limit_left)
    state.scroll_dist_y = extmath.clamp(state.scroll_dist_y, dist_limit_bottom, dist_limit_top)

    -- actuator sizes
    local h_actuator_size = get_actuator_size(content_width, scroll_width)
    local v_actuator_size = get_actuator_size(content_height, scroll_height)

    local possibly_interacting = mnav.is_hovering(scroll_region)
        or mnav.get_dragging(scroll_region)
        or mnav.get_dragging(h_act)
        or mnav.get_dragging(v_act)

    if possibly_interacting or view_request.time > 0 then
        if content_width > scroll_width then
            -- set scrollbar location
            cursor.change_anchor(0, 1)
            cursor.height = scrollbar_thickness

            -- make scroll bar sensor
            mnav.make_sensor(h_bar, smode.block)

            -- set actuator location
            cursor.width = h_actuator_size
            cursor.x = extmath.map(
                state.scroll_dist_x,
                dist_limit_right,
                dist_limit_left,
                scroll_right - h_actuator_size,
                scroll_left
            )

            -- make scroll bar actuator sensor
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
                    dist_limit_left,
                    dist_limit_right,
                    literal_scroll_left,
                    literal_scroll_right,
                    h_actuator_size,
                    projected_placement.left,
                    scroll_region,
                    h_bar,
                    h_act
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
                dist_limit_bottom,
                dist_limit_top,
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
                    dist_limit_top,
                    dist_limit_bottom,
                    literal_scroll_top,
                    literal_scroll_bottom,
                    v_actuator_size,
                    projected_placement.top,
                    scroll_region,
                    v_bar,
                    v_act
                )
            end
        end
    end

    cursor.pop() -- (1)

    draw_data_edit_translation(tid, state.scroll_dist_x, state.scroll_dist_y)

    -- scroll region sensor is made last so it has the highest priority
    mnav.make_sensor(scroll_region, smode.lazy, smode.draggable)

    local at_left = state.scroll_dist_x == dist_limit_left
    local at_top = state.scroll_dist_y == dist_limit_top
    local at_right = state.scroll_dist_x == dist_limit_right
    local at_bottom = state.scroll_dist_y == dist_limit_bottom

    return at_left, at_top, at_right, at_bottom
end

return scroll
