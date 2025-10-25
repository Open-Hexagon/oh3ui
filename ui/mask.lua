local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")

local mask = {}

---Mask everything outside of the cursor. Further draw operations will not affect masked areas.
---Mouse interaction is cancelled in masked areas.
---Make sure to pop the mask when you're done!
---@return integer placement_id
function mask.push()
    cursor.place()
    return draw_queue.push_scissor(placement.left, placement.top, placement.right, placement.bottom)
end

---stack underflow checking is done during drawing
mask.pop = draw_queue.pop_scissor

return mask
