local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local placement = cursor.placement
local mouse = require("ui.control.mouse")
local hoverbox = require("ui.sensor.hoverbox")
local clickbox = require("ui.sensor.clickbox")
local dragbox = require("ui.sensor.dragbox")
local extmath = require("ui.extmath")
local theme = require("ui.theme")
local mask = require("ui.mask")

local scroll = {}

local scrollbar_thickness = 8
local scrollbar_thickness_inactive = scrollbar_thickness * 0.5
local minimum_scrollbar_actuator_length = 20
local minimum_scrollbar_length = 1.5 * minimum_scrollbar_actuator_length
local mouse_wheel_scroll_distance = 10

local in_scroll = false

---Start a scrolled area. The current cursor location is used as the cutout area. Does not reshape the cursor
---If the cursor is degenerate then no scroll area is created and false is returned (nothing would have been drawn anyways).
---Otherwise, returns true.
---@param state table
---@return boolean
function scroll.start(state)
    if cursor.is_degenerate() then
        return false
    end

    if in_scroll then
        error("nested scrolls are not allowed")
    end

    state.scroll_dist_x = state.scroll_dist_x or 0
    state.scroll_dist_y = state.scroll_dist_y or 0

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

--[[
    * Note:
    The horizontal and vertical scroll code are near duplicates but I'm going to leave it
    since it'll get really confusing without explicit variable names.

    Extracting stuff out into functions is going to be a nightmare because of the
    interdependent state fields and probably isn't going to make it any more readable
]]

---Finish a scrolled area. The combination of the current cursor location and the original scroll area is used to calculate the scroll limits
---A cursor area should probably be used and finished right before this is run so that the cursor surrounds all created elements.
---@param state table make sure that this is the same table as the corresponding starting function!
function scroll.finish(state)
    mask.pop()
    cursor.remove_translation()

    state.at_bottom = false

    -- do scrolling if hovering or dragging any scrollbar (1)
    if state.hovering or state.dragging then
        -- will be set to true if any scrollbar is being dragged
        state.dragging = false

        -- combine to ensure the content area surrounds the scroll area
        cursor.combine(true)
        local content_width, content_height = cursor.width, cursor.height
        local content_top, content_bottom = cursor.tb()
        local content_left, content_right = cursor.lr()

        -- return cursor back to scroll area shape
        cursor.peek()
        local scroll_width, scroll_height = cursor.width, cursor.height

        -- horizontal scrolling (disabled if dragging vertically) (10)
        if content_width > scroll_width and not (state.v_act and (state.v_act.dragging or state.v_act.holding)) then
            -- get scroll area translation limits
            local scroll_left, scroll_right = cursor.lr()
            -- should be <=0 (negative values scroll right)
            local scroll_limit_right = scroll_right - content_right
            -- should be >=0 (negative values scroll right)
            local scroll_limit_left = scroll_left - content_left

            -- do scrollbar only if scroll width is wide enough (11)
            if scroll_width >= minimum_scrollbar_length then
                -- state tables for scrollbar and actuator
                state.h_bar = state.h_bar or {}
                state.h_act = state.h_act or {}

                -- actuator sizes
                local actuator_size = get_actuator_size(content_width, scroll_width)
                local half_actuator_size = actuator_size * 0.5

                -- limits of effective mouse range
                local mouse_limit_left, mouse_limit_right

                -- set scrollbar location
                cursor.change_anchor(0, 1)
                cursor.height = scrollbar_thickness

                do -- scrollbar background
                    clickbox(state.h_bar)

                    -- use placement table since we want the literal element location
                    mouse_limit_left, mouse_limit_right =
                        placement.left + half_actuator_size, placement.right - half_actuator_size

                    -- goto location if the bar is clicked outside of the actuator
                    if state.h_bar.clicked and not state.h_act.hovering then
                        state.scroll_dist_x = extmath.map(
                            extmath.clamp(mouse.x, mouse_limit_left, mouse_limit_right),
                            mouse_limit_left,
                            mouse_limit_right,
                            scroll_limit_left,
                            scroll_limit_right
                        )
                    end
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

                do -- scrollbar actuator
                    dragbox(state.h_act, "pass")

                    -- move the scrollbar and region if dragging
                    if state.h_act.dragging then
                        state.dragging = true
                        if state.h_act.started_dragging then
                            state.h_act.mouse_offset = (mouse.x - (placement.left + half_actuator_size))
                        end
                        state.scroll_dist_x = extmath.map(
                            extmath.clamp(mouse.x - state.h_act.mouse_offset, mouse_limit_left, mouse_limit_right),
                            mouse_limit_left,
                            mouse_limit_right,
                            scroll_limit_left,
                            scroll_limit_right
                        )
                    end

                    -- shrink the actuator if needed
                    if not (state.h_bar.hovering or state.h_act.dragging) then
                        cursor.height = scrollbar_thickness_inactive
                    end

                    -- draw the actuator
                    primitive.slot(
                        (state.h_act.dragging or state.h_act.holding) and theme.grabbed_scrollbar or theme.scrollbar
                    )
                end

                -- mouse wheel (disabled if dragging)
                if not state.h_act.dragging then
                    state.scroll_dist_x = state.scroll_dist_x + mouse.wheel_dx * -mouse_wheel_scroll_distance
                end
            else -- else clause of do scrollbars (11)
                -- the mouse wheel should still work even if the scrollbar isn't there
                state.scroll_dist_x = state.scroll_dist_x + mouse.wheel_dx * -mouse_wheel_scroll_distance
            end -- end of do scrollbars (11)

            -- apply scroll limits
            state.scroll_dist_x = extmath.clamp(state.scroll_dist_x, scroll_limit_right, scroll_limit_left)

            -- return to scroll area
            cursor.peek()
        end -- end of horizontal scrolling (10)

        -- vertical scrolling (disabled if dragging horizontally) (20)
        if content_height > scroll_height and not (state.h_act and (state.h_act.dragging or state.h_act.holding)) then
            -- get scroll translation limits
            local scroll_top, scroll_bottom = cursor.tb()
            -- should be <=0 (negative values scroll down)
            local scroll_limit_bottom = scroll_bottom - content_bottom
            -- should be >=0 (positive values scroll up)
            local scroll_limit_top = scroll_top - content_top

            -- do scrollbars only if the scroll height is tall enough (21)
            if scroll_height >= minimum_scrollbar_length then
                -- state tables for scrollbar and actuator
                state.v_bar = state.v_bar or {}
                state.v_act = state.v_act or {}

                local actuator_size = get_actuator_size(content_height, scroll_height)
                local half_actuator_size = actuator_size * 0.5

                -- limits of effective mouse range
                local mouse_limit_top, mouse_limit_bottom

                -- set scrollbar location
                cursor.change_anchor(1, 0)
                cursor.width = scrollbar_thickness

                do -- scrollbar background
                    clickbox(state.v_bar)

                    -- use placement table since we want the literal element location
                    mouse_limit_top, mouse_limit_bottom =
                        placement.top + half_actuator_size, placement.bottom - half_actuator_size

                    -- goto location if the bar is clicked outside of the actuator
                    if state.v_bar.clicked and not state.v_act.hovering then
                        state.scroll_dist_y = extmath.map(
                            extmath.clamp(mouse.y, mouse_limit_top, mouse_limit_bottom),
                            mouse_limit_top,
                            mouse_limit_bottom,
                            scroll_limit_top,
                            scroll_limit_bottom
                        )
                    end
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

                do -- scrollbar actuator
                    dragbox(state.v_act, "pass")

                    -- move the scrollbar and region if dragging
                    if state.v_act.dragging then
                        state.dragging = true
                        if state.v_act.started_dragging then
                            state.v_act.mouse_offset = (mouse.y - (placement.top + half_actuator_size))
                        end
                        state.scroll_dist_y = extmath.map(
                            extmath.clamp(mouse.y - state.v_act.mouse_offset, mouse_limit_top, mouse_limit_bottom),
                            mouse_limit_top,
                            mouse_limit_bottom,
                            scroll_limit_top,
                            scroll_limit_bottom
                        )
                    end

                    -- shrink the actuator if needed
                    if not (state.v_bar.hovering or state.v_act.dragging) then
                        cursor.width = scrollbar_thickness_inactive
                    end

                    -- draw the actuator
                    primitive.slot(
                        (state.v_act.dragging or state.v_act.holding) and theme.grabbed_scrollbar or theme.scrollbar
                    )
                end

                -- mouse wheel (disabled if dragging)
                if not state.v_act.dragging then
                    state.scroll_dist_y = state.scroll_dist_y + mouse.wheel_dy * mouse_wheel_scroll_distance
                end
            else -- else clause of do scrollbars (21)
                -- the mouse wheel should still work even if the scrollbar isn't there
                state.scroll_dist_y = state.scroll_dist_y + mouse.wheel_dy * mouse_wheel_scroll_distance
            end -- end of do scrollbars (21)

            -- apply scroll limits
            state.scroll_dist_y = extmath.clamp(state.scroll_dist_y, scroll_limit_bottom, scroll_limit_top)

            state.at_bottom = state.scroll_dist_y == scroll_limit_bottom
        end -- end of vertical scrolling (20)
    end -- end of do scrolling (1)

    cursor.pop()

    -- check if hovering the whole scroll area
    hoverbox(state, "lazy")

    in_scroll = false
end

---Moves the current cursor location into
function scroll.move_into_view()

end

return scroll
