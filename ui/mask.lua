local cursor = require("ui.cursor")
local placement = cursor.placement
local draw_queue = require("ui.draw_queue")
local volatile_data = require("ui.shared_data").volatile

local mask = {}

---Mask everything outside of the cursor. Further draw operations will not affect masked areas.
---Mouse interaction is cancelled in masked areas.
---Make sure to pop the mask when you're done!
function mask.push()
    volatile_data.mask_index = volatile_data.mask_index + 1
    cursor.place()
    draw_queue.push_scissor(placement.left, placement.top, placement.right, placement.bottom)
end

---Removes the last applied mask.
function mask.pop()
    if volatile_data.mask_index == volatile_data.mask_base_index then
        error("scissor stack underflow")
    end
    volatile_data.mask_index = volatile_data.mask_index + 1
    draw_queue.pop_scissor()
end

return mask
