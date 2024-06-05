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
---@param max_width number?
---@param max_height number?
function collapse.done(max_width, max_height)
    local bounds = area.get_bounds()

    -- nil as max means max is as large as it can possibly be
    max_width = max_width or math.huge
    max_height = max_height or math.huge

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
