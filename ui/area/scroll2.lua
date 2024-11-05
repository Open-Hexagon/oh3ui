local draw_queue = require("ui.draw_queue")
local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local edge = cursor.edge
local mouse = require("ui.mouse")
local hoverbox = require("ui.sensor.hoverbox")

local scroll = {}

---Start a scrolled area. The current cursor location is used as the cutout area.
---If the cursor is degenerate then no scroll area is created and false is returned (nothing would have been drawn anyways).
---Otherwise, returns true.
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

    -- make it seem like the origin is at the top-left corner of the scroll area
    cursor.apply_translation(state.scroll_dist_x, state.scroll_dist_y)

    -- -- reset cursor values
    -- cursor.reset(cursor.width, cursor.height)

    -- this is just used to measure the area covered by all included elements
    cursor.begin_area()
    return true
end

function scroll.finish(state)
    primitive.pop_mask()

    cursor.end_area()
    local content_width = cursor.width
    local content_height = cursor.height

    -- return curor back to its original state
    cursor.remove_translation()
    cursor.pop()

    hoverbox(state, "lazy")

    if state.hovering then
        state.scroll_dist_x = state.scroll_dist_x + mouse.wheel_dx * -10
        state.scroll_dist_y = state.scroll_dist_y + mouse.wheel_dy * 10
    end
end

return scroll
