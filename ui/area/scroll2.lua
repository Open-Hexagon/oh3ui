local draw_queue = require("ui.draw_queue")
local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local edge = cursor.edge


local scroll = {}



---Start a scrolled area. The current cursor location is used as the cutout area.
---If the cursor is degenerate then no scroll area is created and false is returned (nothing would have been drawn anyways).
---Otherwise, returns true.
---@return boolean
function scroll.start(state)
    if cursor.is_degenerate() then
        return false
    end

    primitive.push_mask()
    -- this is just used to measure the area covered by all included elements
    area.start()

    return true
end



function scroll.finish()
    area.finish()
    


    primitive.pop_mask()
end

return scroll