local cursor = require("ui.cursor")
local extmath = require("ui.extmath")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode
local primitive = require("ui.primitive")
local placement = cursor.placement
local theme = require("ui.theme")

---todo
---keyboard navigation can request to scroll to a specific location
---dragging on a scroll region will should also scroll like on a touchscreen

local scroll = {}

local scrollbar_thickness = 8
local scrollbar_thickness_inactive = scrollbar_thickness * 0.5
local minimum_scrollbar_actuator_length = 8
local mouse_wheel_scroll_distance = 10

local in_scroll = false

function scroll.start(state)
    if cursor.is_degenerate() then
        return false
    end

    if in_scroll then
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

    in_scroll = true

    return true
end

local function get_actuator_size(content_size, scroll_size)
    return math.max(scroll_size * scroll_size / content_size, minimum_scrollbar_actuator_length)
end

function scroll.finish(state)
    if not in_scroll then
        error("scroll.finish called with no active scroll")
    end

    mask.pop()
    cursor.remove_translation()

    local scroll_region = mnav.declare_sensor_id()
    local h_act = mnav.declare_sensor_id()
    local h_bar = mnav.declare_sensor_id()
    local v_act = mnav.declare_sensor_id()
    local v_bar = mnav.declare_sensor_id()

    if mnav.is_hovering(scroll_region) or mnav.get_dragging(scroll_region) or mnav.get_dragging(h_act) or mnav.get_dragging(v_act) then
        -- peek combine to get the size of the content area (must enclose the original scroll area)
        cursor.combine(true)
        local content_width, content_height = cursor.width, cursor.height
        local content_top, content_bottom = cursor.tb()
        local content_left, content_right = cursor.lr()

        -- peek to get the original scroll area size
        cursor.peek()
        local scroll_width, scroll_height = cursor.width, cursor.height

        if content_width > scroll_width then
            -- ensure placement is up to date
            cursor.place()

            -- get scroll area translation limits
            local scroll_left, scroll_right = cursor.lr()
            -- should be <=0 (negative values scroll right)
            local scroll_limit_right = scroll_right - content_right
            -- should be >=0 (negative values scroll right)
            local scroll_limit_left = scroll_left - content_left

            -- actuator sizes
            local actuator_size = get_actuator_size(content_width, scroll_width)
            local half_actuator_size = actuator_size * 0.5

            local mouse_limit_left, mouse_limit_right =
                placement.left + half_actuator_size, placement.right - half_actuator_size

            -- set scrollbar location
            cursor.change_anchor(0, 1)
            cursor.height = scrollbar_thickness

            mnav.make_sensor(h_bar, smode.block)

            -- goto location if the bar is held outside of the actuator
            if mnav.get_holding(h_bar) and not mnav.is_hovering(h_act) then
                state.scroll_dist_x = extmath.map(
                    extmath.clamp(mnav.x, mouse_limit_left, mouse_limit_right),
                    mouse_limit_left,
                    mouse_limit_right,
                    scroll_limit_left,
                    scroll_limit_right
                )
            end

            -- set actuator location
            cursor.width = actuator_size
            cursor.x = extmath.map(
                state.scroll_dist_x,
                scroll_limit_right,
                scroll_limit_left,
                scroll_right - actuator_size,
                scroll_left
            )

            mnav.make_sensor(h_act, smode.draggable)

            -- move the scrollbar and region if dragging
            if mnav.get_dragging(h_act) then
                if mnav.get_started_dragging(h_act) then
                    state._mouse_offset = (mnav.x - (placement.left + half_actuator_size))
                end
                state.scroll_dist_x = extmath.map(
                    extmath.clamp(mnav.x - state._mouse_offset, mouse_limit_left, mouse_limit_right),
                    mouse_limit_left,
                    mouse_limit_right,
                    scroll_limit_left,
                    scroll_limit_right
                )
            end

            -- shrink the actuator if needed
            if not (mnav.is_hovering(h_bar) or mnav.get_dragging(h_act)) then
                cursor.height = scrollbar_thickness_inactive
            end

            -- draw the actuator
            primitive.slot(
                (mnav.get_dragging(h_act) or mnav.get_holding(h_act)) and theme.grabbed_scrollbar or theme.scrollbar
            )

            -- mouse wheel (disabled if dragging)
            if not mnav.get_dragging(h_act) then
                state.scroll_dist_x = extmath.clamp(
                    state.scroll_dist_x + mnav.wheel_dx * -mouse_wheel_scroll_distance,
                    scroll_limit_right,
                    scroll_limit_left
                )
            end

            if mnav.get_dragging(scroll_region) then
                state.scroll_dist_x = extmath.clamp(
                    state.scroll_dist_x + mnav.dx,
                    scroll_limit_right,
                    scroll_limit_left
                )
            end

            state.at_left = state.scroll_dist_x == scroll_limit_left
            state.at_right = state.scroll_dist_x == scroll_limit_right
        end

        if content_height > scroll_height then
            -- ensure placement is up to date
            cursor.peek()
            cursor.place()

            -- get scroll translation limits
            local scroll_top, scroll_bottom = cursor.tb()
            -- should be <=0 (negative values scroll down)
            local scroll_limit_bottom = scroll_bottom - content_bottom
            -- should be >=0 (positive values scroll up)
            local scroll_limit_top = scroll_top - content_top

            local actuator_size = get_actuator_size(content_height, scroll_height)
            local half_actuator_size = actuator_size * 0.5

            local mouse_limit_top, mouse_limit_bottom =
                placement.top + half_actuator_size, placement.bottom - half_actuator_size

            -- set scrollbar location
            cursor.change_anchor(1, 0)
            cursor.width = scrollbar_thickness

            mnav.make_sensor(v_bar, smode.block)

            -- goto location if the bar is held outside of the actuator
            if mnav.get_holding(v_bar) and not mnav.is_hovering(v_act) then
                state.scroll_dist_y = extmath.map(
                    extmath.clamp(mnav.y, mouse_limit_top, mouse_limit_bottom),
                    mouse_limit_top,
                    mouse_limit_bottom,
                    scroll_limit_top,
                    scroll_limit_bottom
                )
            end

            -- set actuator location
            cursor.height = actuator_size
            cursor.y = extmath.map(
                state.scroll_dist_y,
                scroll_limit_bottom,
                scroll_limit_top,
                scroll_bottom - actuator_size,
                scroll_top
            )

            mnav.make_sensor(v_act, smode.draggable)

            -- move the scrollbar and region if dragging
            if mnav.get_dragging(v_act) then
                if mnav.get_started_dragging(v_act) then
                    state._mouse_offset = (mnav.y - (placement.top + half_actuator_size))
                end
                state.scroll_dist_y = extmath.map(
                    extmath.clamp(mnav.y - state._mouse_offset, mouse_limit_top, mouse_limit_bottom),
                    mouse_limit_top,
                    mouse_limit_bottom,
                    scroll_limit_top,
                    scroll_limit_bottom
                )
            end

            -- shrink the actuator if needed
            if not (mnav.is_hovering(v_bar) or mnav.get_dragging(v_act)) then
                cursor.width = scrollbar_thickness_inactive
            end

            -- draw the actuator
            primitive.slot(
                (mnav.get_dragging(v_act) or mnav.get_holding(v_act)) and theme.grabbed_scrollbar or theme.scrollbar
            )

            -- mouse wheel (disabled if dragging)
            if not mnav.get_dragging(v_act) then
                state.scroll_dist_y = extmath.clamp(
                    state.scroll_dist_y + mnav.wheel_dy * mouse_wheel_scroll_distance,
                    scroll_limit_bottom,
                    scroll_limit_top
                )
            end

            if mnav.get_dragging(scroll_region) then
                state.scroll_dist_y = extmath.clamp(
                    state.scroll_dist_y + mnav.dy,
                    scroll_limit_bottom,
                    scroll_limit_top
                )
            end

            state.at_top = state.scroll_dist_y == scroll_limit_top
            state.at_bottom = state.scroll_dist_y == scroll_limit_bottom
        end
    end

    cursor.pop()

    mnav.make_sensor(scroll_region, smode.lazy, smode.draggable)

    in_scroll = false
end

return scroll
