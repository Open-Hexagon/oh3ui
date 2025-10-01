local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")

local tooltip = {}

-- ---@param text string
-- return function(state, text)
--     cursor.push()
--     cursor.pop()
-- end

--[[
    anchor: cursor, element
        tooltop will align itself to the cursor or element

    prefer: n, ne, e, se, s, sw, w, nw
        Which side the tooltip tries to stay at
    
        If tooltip is pushed such that it will intersect the element, it will flip to the opposite side.


]]

---comment
---@param text string
function tooltip.new(text, ...) end

function tooltip.add_to_queue() end

return tooltip
