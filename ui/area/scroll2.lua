local draw_queue = require("ui.draw_queue")
local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local placement = cursor.placement
local mouse = require("ui.mouse")
local hoverbox = require("ui.sensor.hoverbox")
local clickbox = require("ui.sensor.clickbox")
local dragbox = require("ui.sensor.dragbox")
local extmath = require("ui.extmath")
local theme = require("ui.theme")

local scroll = {}

local scrollbar_thickness = 8
local scrollbar_thickness_inactive = scrollbar_thickness * 0.5

---Start a scrolled area. The current cursor location is used as the cutout area.
---If the cursor is degenerate then no scroll area is created and false is returned (nothing would have been drawn anyways).
---Otherwise, returns true.
---@param state table
---@return boolean
function scroll.start(state)
    if cursor.is_degenerate() then
        return false
    end

    state.scroll_dist_x = state.scroll_dist_x or 0
    state.scroll_dist_y = state.scroll_dist_y or 0

    -- save the current cursor
    cursor.push()

    -- mask away everything outside of the region
    primitive.push_mask()

    -- move the contents of the scroll area
    cursor.apply_translation(
        state.scroll_dist_x, -- positive values scroll left
        state.scroll_dist_y -- positive values scroll up
    )

    return true
end

local function get_actuator_size(content_size, scroll_size)
    return scroll_size * scroll_size / content_size
end

---Finish a scrolled area. The combination of the current cursor location and the original scroll area is used to calculate the scroll limits
---A cursor area should probably be used and finished right before this is run so that the cursor surrounds all created elements.
---@param state table make sure that this is the same table as the corresponding starting function!
function scroll.finish(state)
    primitive.pop_mask()
    cursor.remove_translation()

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

        -- horizontal scrolling (disabled if dragging vertically)
        if content_width > scroll_width and not (state.v_act and state.v_act.dragging) then
            -- get scroll area boundaries
            local scroll_left, scroll_right = cursor.lr()

            -- translation limits
            -- should be <=0 (negative values scroll right)
            local scroll_limit_right = scroll_right - content_right
            -- should be >=0 (negative values scroll right)
            local scroll_limit_left = scroll_left - content_left

            -- actuator sizes
            local actuator_size = get_actuator_size(content_width, scroll_width)
            local half_actuator_size = actuator_size * 0.5

            -- state tables for scrollbar and actuator
            state.h_bar = state.h_bar or {}
            state.h_act = state.h_act or {}

            -- set scrollbar location
            cursor.change_anchor(0, 1)
            cursor.height = scrollbar_thickness

            -- scrollbar background
            clickbox(state.h_bar)

            local goto_limit_left, goto_limit_right =
                placement.left + half_actuator_size, placement.right - half_actuator_size

            -- goto location if the bar is clicked outside of the actuator
            if state.h_bar.clicked and not state.h_act.hovering then
                state.scroll_dist_x = extmath.map(
                    extmath.clamp(mouse.x, goto_limit_left, goto_limit_right),
                    goto_limit_left,
                    goto_limit_right,
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

            -- actuator sensor
            dragbox(state.h_act, "pass")

            -- do dragging action
            if state.h_act.dragging then
                state.dragging = true
                if state.h_act.started_dragging then
                    state.h_act.mouse_offset = (mouse.x - (placement.left + half_actuator_size))
                end
                state.scroll_dist_x = extmath.map(
                    extmath.clamp(mouse.x - state.h_act.mouse_offset, goto_limit_left, goto_limit_right),
                    goto_limit_left,
                    goto_limit_right,
                    scroll_limit_left,
                    scroll_limit_right
                )
            end

            -- draw the actuator
            -- shrink the actuator if needed
            -- TODO | Issue: minor flickering issue if mouse is released after dragging while still hovering the actuator
            -- TODO | since hovering data is received one frame later.
            if not (state.h_bar.hovering or state.h_act.dragging) then
                cursor.height = scrollbar_thickness_inactive
            end
            primitive.slot(theme.white)

            -- mouse wheel (disabled if dragging)
            if not state.h_act.dragging then
                state.scroll_dist_x = state.scroll_dist_x + mouse.wheel_dx * -10
            end

            -- apply scroll limits
            state.scroll_dist_x = extmath.clamp(state.scroll_dist_x, scroll_limit_right, scroll_limit_left)
        end

        -- vertical scrolling (disabled if dragging horizontally)
        if content_height > scroll_height and not (state.h_act and state.h_act.dragging) then
            -- we need this in case the horizontal scrolling has run
            cursor.peek()

            -- get scroll boundaries-- get scroll boundaries
            local scroll_top, scroll_bottom = cursor.tb()

            -- translation limits
            -- should be <=0 (negative values scroll down)
            local scroll_limit_bottom = scroll_bottom - content_bottom
            -- should be >=0 (positive values scroll up)
            local scroll_limit_top = scroll_top - content_top

            local actuator_size = get_actuator_size(content_height, scroll_height)
            local half_actuator_size = actuator_size * 0.5

            -- state tables for scrollbar and actuator
            state.v_bar = state.v_bar or {}
            state.v_act = state.v_act or {}

            -- set scrollbar location
            cursor.change_anchor(1, 0)
            cursor.width = scrollbar_thickness

            -- scrollbar background
            clickbox(state.v_bar)

            local goto_limit_top, goto_limit_bottom =
                placement.top + half_actuator_size, placement.bottom - half_actuator_size

            -- goto location if the bar is clicked outside of the actuator
            if state.v_bar.clicked and not state.v_act.hovering then
                state.scroll_dist_y = extmath.map(
                    extmath.clamp(mouse.y, goto_limit_top, goto_limit_bottom),
                    goto_limit_top,
                    goto_limit_bottom,
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
            -- actuator sensor
            dragbox(state.v_act, "pass")

            -- do dragging action
            if state.v_act.dragging then
                state.dragging = true
                if state.v_act.started_dragging then
                    state.v_act.mouse_offset = (mouse.y - (placement.top + half_actuator_size))
                end
                state.scroll_dist_y = extmath.map(
                    extmath.clamp(mouse.y - state.v_act.mouse_offset, goto_limit_top, goto_limit_bottom),
                    goto_limit_top,
                    goto_limit_bottom,
                    scroll_limit_top,
                    scroll_limit_bottom
                )
            end

            -- draw the actuator
            -- shrink the actuator if needed
            -- TODO | Issue: minor flickering issue if mouse is released after dragging while still hovering the actuator
            -- TODO | since hovering data is received one frame later.
            if not (state.v_bar.hovering or state.v_act.dragging) then
                cursor.width = scrollbar_thickness_inactive
            end
            primitive.slot(theme.white)

            -- mouse wheel (disabled if dragging)
            if not state.v_act.dragging then
                state.scroll_dist_y = state.scroll_dist_y + mouse.wheel_dy * 10
            end
            -- apply scroll limits
            state.scroll_dist_y = extmath.clamp(state.scroll_dist_y, scroll_limit_bottom, scroll_limit_top)

            state.at_bottom = state.scroll_dist_y == scroll_limit_bottom
        end
    end

    cursor.pop()

    -- check if hovering the whole scroll area
    hoverbox(state, "lazy")
end

return scroll
