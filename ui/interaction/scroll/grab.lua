local events = require("ui.event_queue")
local area = require("ui.area")

local grab = {}

local function is_in_scrollbar(scroll_state, x, y)
    local scrollbar = scroll_state.scrollbar
    return x >= scrollbar.left and x <= scrollbar.right and y >= scrollbar.top and y <= scrollbar.bottom
end

local grabbed_a_scrollbar_already_this_frame = false

function grab.reset()
    grabbed_a_scrollbar_already_this_frame = false
end

---handle scrollbar grab scroll interaction
---@param scroll_state table
function grab.update(scroll_state)
    local data = area.get_extra_data()
    local x, y = love.graphics.inverseTransformPoint(love.mouse.getPosition())

    -- show the scrollbar when hovering or grabbing it
    if is_in_scrollbar(scroll_state, x, y) or scroll_state.scrollbar_grabbed_at then
        scroll_state.last_interaction_time = love.timer.getTime()
    end

    -- handle events
    for event in events.iterate("mouse.*") do
        local name = event[1]
        -- grab scrollbar when pressing down onto it and if no other scrollbar has been grabbed in this frame
        if name == "mousepressed" and is_in_scrollbar(scroll_state, x, y) and not grabbed_a_scrollbar_already_this_frame then
            -- save the relative position on the scrollbar to set scroll position later
            if data.direction == "vertical" then
                scroll_state.scrollbar_grabbed_at = y - scroll_state.scrollbar.top
            else -- data.direction == "horizontal"
                scroll_state.scrollbar_grabbed_at = x - scroll_state.scrollbar.left
            end
            grabbed_a_scrollbar_already_this_frame = true
        end
        -- stop grabbing when releasing no matter the cursor position
        if name == "mousereleased" then
            scroll_state.scrollbar_grabbed_at = nil
        end
    end

    if scroll_state.scrollbar_grabbed_at then
        local scrollbar = scroll_state.scrollbar
        local scroll_position = 0
        local bounds = area.get_bounds()

        -- calculating scroll position
        if data.direction == "vertical" then
            -- area length - scrollbar length
            local max_scrollbar_position = data.area_length - (scrollbar.bottom - scrollbar.top)
            -- new scrollbar top according to current mouse position
            -- offset by bounds.top so 0 is at the start of area, not of screen
            local new_top = y - scroll_state.scrollbar_grabbed_at - bounds.top
            -- scroll percentage = new_top / max_scrollbar_position
            -- max scroll = data.overflow
            scroll_position = new_top * data.overflow / max_scrollbar_position

        else -- data.direction == "horizontal"
            -- area length - scrollbar length
            local max_scrollbar_position = data.area_length - (scrollbar.right - scrollbar.left)
            -- new scrollbar left position according to current mouse position
            -- offset by bounds.left so 0 is at the start of area, not of screen
            local new_left = x - scroll_state.scrollbar_grabbed_at - bounds.left
            -- scroll percentage = new_left / max_scrollbar_position
            -- max scroll = data.overflow
            scroll_position = new_left * data.overflow / max_scrollbar_position
        end

        require("ui.interaction.scroll").go_to(scroll_position, 0, "none")
    end
end

return grab
