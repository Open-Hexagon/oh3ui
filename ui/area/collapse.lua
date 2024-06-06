local area = require("ui.area")
local draw_queue = require("ui.draw_queue")
local collapse = {}

---start a collapse area
function collapse.start()
    area.start()
    -- put scissor here once bounds are known
    draw_queue.placeholder()
end

---finish the collapse area
---@param width_factor number?
---@param height_factor number?
function collapse.done(width_factor, height_factor)
    local bounds = area.get_bounds()

    -- no cutoff by default
    local max_width, max_height = math.huge, math.huge

    -- set max if factor is not nil
    if width_factor then
        max_width = (bounds.right - bounds.left) * width_factor
    end
    if height_factor then
        max_height = (bounds.bottom - bounds.top) * height_factor
    end

    -- modify bounds to limit width/height
    if bounds.right - bounds.left > max_width then
        bounds.right = bounds.left + max_width
    end
    if bounds.bottom - bounds.top > max_height then
        bounds.bottom = bounds.top + max_height
    end

    -- finish area with modified bounds
    area.done()

    -- set scissor to cut elements off
    draw_queue.put_next_in_last_placeholder()
    draw_queue.push_scissor(bounds.left, bounds.top, bounds.right, bounds.bottom)
    -- remove it once area is done
    draw_queue.pop_scissor()
end

return collapse
