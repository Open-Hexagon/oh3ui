local area = require("ui.area")
local draw_queue = require("ui.draw_queue")
local collapse = {}

---start a collapse area
---@param collapse_state table
function collapse.start(collapse_state)
    area.start()
    -- put scissor here once bounds are known
    draw_queue.placeholder()

    -- has to be persisted as it is always used in a delayed manner
    collapse_state.cutout = collapse_state.cutout or {}

    local data = area.get_extra_data()
    data.state = collapse_state
end

---finish the collapse area
function collapse.done()
    local bounds = area.get_bounds()
    local data = area.get_extra_data()
    local collapse_state = data.state

    -- no cutoff by default
    local max_width, max_height = math.huge, math.huge

    -- set max if factor is not nil
    if collapse_state.width_factor then
        max_width = (bounds.right - bounds.left) * collapse_state.width_factor
    end
    if collapse_state.height_factor then
        max_height = (bounds.bottom - bounds.top) * collapse_state.height_factor
    end

    -- modify bounds to limit width/height
    if bounds.right - bounds.left > max_width then
        bounds.right = bounds.left + max_width
    end
    if bounds.bottom - bounds.top > max_height then
        bounds.bottom = bounds.top + max_height
    end

    -- modify cutout to prevent interaction of invisible elements (in screen space)
    local x1, y1 = love.graphics.transformPoint(bounds.left, bounds.top)
    local x2, y2 = love.graphics.transformPoint(bounds.right, bounds.bottom)
    collapse_state.cutout.left = x1
    collapse_state.cutout.top = y1
    collapse_state.cutout.right = x2
    collapse_state.cutout.bottom = y2

    -- finish area with modified bounds
    area.done()

    -- set scissor to cut elements off
    draw_queue.put_next_in_last_placeholder()
    draw_queue.push_scissor(bounds.left, bounds.top, bounds.right, bounds.bottom)
    -- remove it once area is done
    draw_queue.pop_scissor()
end

return collapse
