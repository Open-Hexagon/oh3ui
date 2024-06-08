local area = require("ui.area")
local drag = require("ui.interaction.drag")

local grab = {}

local function is_in_scrollbar(scroll_state, x, y)
    local scrollbar = scroll_state.scrollbar
    return drag.is_pos_in_bounds(x, y, scrollbar.left, scrollbar.top, scrollbar.right, scrollbar.bottom)
end

local grabbed_a_scrollbar_already_this_frame = false

---reset interaction state
function grab.reset()
    grabbed_a_scrollbar_already_this_frame = false
end

---handle scrollbar grab scroll interaction
---@param scroll_state table
function grab.update(scroll_state)
    local data = area.get_extra_data()

    local screen_x, screen_y = love.mouse.getPosition()
    local x, y = love.graphics.inverseTransformPoint(screen_x, screen_y)

    -- show the scrollbar when hovering or grabbing it
    if is_in_scrollbar(scroll_state, x, y) or scroll_state.scrollbar_grabbed_at then
        scroll_state.last_interaction_time = love.timer.getTime()
    end

    -- do actual drag interaction
    local scrollbar = scroll_state.scrollbar
    local left, top, _, _, grabbed = drag.update(scroll_state, scrollbar.left, scrollbar.top, scrollbar.right, scrollbar.bottom, not grabbed_a_scrollbar_already_this_frame)
    grabbed_a_scrollbar_already_this_frame = grabbed

    if grabbed then
        local scroll_position = 0
        local bounds = area.get_bounds()

        -- calculating scroll position
        if data.direction == "vertical" then
            -- area length - scrollbar length
            local max_scrollbar_position = data.area_length - (scrollbar.bottom - scrollbar.top)
            -- new scrollbar top according to current mouse position
            -- offset by bounds.top so 0 is at the start of area, not of screen
            local new_top = top - bounds.top
            -- scroll percentage = new_top / max_scrollbar_position
            -- max scroll = data.overflow
            scroll_position = new_top * data.overflow / max_scrollbar_position

        else -- data.direction == "horizontal"
            -- area length - scrollbar length
            local max_scrollbar_position = data.area_length - (scrollbar.right - scrollbar.left)
            -- new scrollbar left position according to current mouse position
            -- offset by bounds.left so 0 is at the start of area, not of screen
            local new_left = left - bounds.left
            -- scroll percentage = new_left / max_scrollbar_position
            -- max scroll = data.overflow
            scroll_position = new_left * data.overflow / max_scrollbar_position
        end

        require("ui.interaction.scroll").go_to(scroll_position, 0, "none")
    end
end

return grab
