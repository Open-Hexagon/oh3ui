local scroll_interaction = require("ui.interaction.scroll")
local theme = require("ui.theme")
local area = require("ui.area")

local scroll = {}

---swaps the coordinates if scroll is vertical so that the first one is always the scroll direction
---@param scroll_direction string  "vertical" or "horizontal"
---@param x number
---@param y number
---@return number
---@return number
local function swap_if_vertical(scroll_direction, x, y)
    if scroll_direction == "vertical" then
        return y, x
    end
    -- assuming scroll_direction == "horizontal"
    return x, y
end

---start a scroll area
---@param scroll_state table
---@param scroll_direction string  "horizontal" or "vertical"
---@param max_length number  the size (in scroll direction) after which scrolling should start
function scroll.start(scroll_state, scroll_direction, max_length)
    scroll_state.position = scroll_state.position or 0
    -- only persist to not recreate table every time
    scroll_state.cutout = scroll_state.cutout or {}

    area.start()

    -- store current scroll area data for later use
    local data = area.get_extra_data()
    data.state = scroll_state
    data.direction = scroll_direction
    data.max_length = max_length

    -- translate all elements in the area based on scroll position
    love.graphics.translate(swap_if_vertical(scroll_direction, -scroll_state.position, 0))
end

local SCROLLBAR_THICKNESS = 10

---calculates the scrollbar position and changes the current scroll state accordingly
local function calculate_scrollbar_position()
    local data = area.get_extra_data()
    local scroll_state = data.state

    -- only persist to not recreate table every time
    scroll_state.scrollbar = scroll_state.scrollbar or {}
    local scrollbar = scroll_state.scrollbar

    -- scrollbar to container size ratio = container to content size ratio
    -- scrollbar_length / container_length = container_length / content_length
    -- => scrollbar_length = container_length ^ 2 / content_length
    local length = data.area_length ^ 2 / (data.area_length + data.overflow)

    -- normalized scrollbar position = normalized scroll position
    -- scrollbar_position / (container_length - scrollbar_length) = scroll_position / (content_length - container_length)
    -- scrollbar_position = scroll_position * (container_length - scrollbar_length) / (content_length - container_length)
    --  simplify last part using: content_length - container_length = container_length + overflow - container_length = overflow
    -- scroll_position = scroll_position * (container_length - scrollbar_length) / overflow
    local position = scroll_state.position * (data.area_length - length) / data.overflow

    local bounds = area.get_bounds()

    if data.direction == "vertical" then
        scrollbar.top = bounds.top + position
        scrollbar.bottom = scrollbar.top + length

        -- position on the right side of the area
        scrollbar.right = bounds.right
        scrollbar.left = bounds.right - SCROLLBAR_THICKNESS

    else -- data.direction == "horizontal"
        scrollbar.left = bounds.left + position
        scrollbar.right = scrollbar.left + length

        -- position on the bottom side of the area
        scrollbar.bottom = bounds.bottom
        scrollbar.top = bounds.bottom - SCROLLBAR_THICKNESS
    end
end

---draw the scroll area
function scroll.done()
    -- width and height of total content
    local bounds = area.get_bounds()
    local width = bounds.right - bounds.left
    local height = bounds.bottom - bounds.top

    -- get scroll data for this area (see scroll.start function)
    local data = area.get_extra_data()
    local scroll_state = data.state
    local direction = data.direction
    local max_length = data.max_length

    -- undo scroll translate
    love.graphics.translate(swap_if_vertical(direction, scroll_state.position, 0))

    -- get length and thickness, where length is size in scroll direction
    local length, thickness = swap_if_vertical(direction, width, height)

    data.overflow = math.max(length - max_length, 0)
    data.area_length = math.min(max_length, length)

    calculate_scrollbar_position()

    -- drawing
    if data.overflow == 0 then
        -- no need to scroll, just draw normally
        area.done()
        area.draw()
        -- don't limit interaction
        scroll_state.cutout.left = nil
        scroll_state.cutout.top = nil
        scroll_state.cutout.right = nil
        scroll_state.cutout.bottom = nil
    else -- overflow > 0
        -- getting box dimensions of scroll area
        local w, h = swap_if_vertical(direction, max_length, thickness)
        -- adjust bounds to account for space not taken thanks to scroll
        bounds.right = bounds.left + w
        bounds.bottom = bounds.top + h
        -- determine cutout area in screen space
        local x1, y1 = love.graphics.transformPoint(bounds.left, bounds.top)
        local x2, y2 = love.graphics.transformPoint(bounds.right, bounds.bottom)
        -- used to limit interaction of elements that are scrolled out of view
        scroll_state.cutout.left = x1
        scroll_state.cutout.top = y1
        scroll_state.cutout.right = x2
        scroll_state.cutout.bottom = y2
        -- update position
        scroll_interaction.update()
        -- remove area from stack to prepare drawing
        area.done()
        -- cut out part of the area that is supposed to be visible
        -- (elements were already translated based on scroll position while drawn into the area, so no need to do it here again)
        love.graphics.setScissor(x1, y1, x2 - x1, y2 - y1)
        area.draw()
        love.graphics.setScissor()

        -- draw scrollbar
        local bar = scroll_state.scrollbar
        -- set scrollbar color based on grabbed state
        if scroll_state.scrollbar_grabbed_at then
            love.graphics.setColor(theme.grabbed_scrollbar_color)
        else
            love.graphics.setColor(
                theme.scrollbar_color[1],
                theme.scrollbar_color[2],
                theme.scrollbar_color[3],
                scroll_state.scrollbar_alpha
            )
        end
        love.graphics.rectangle("fill", bar.left, bar.top, bar.right - bar.left, bar.bottom - bar.top)
    end
end

return scroll
