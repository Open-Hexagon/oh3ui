local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local reserve = require("ui.reserve")

local background = {}



function background.start()
    
    cursor.start_area()
end

---Finish the background
---@param pad number
---@param color table?
function background.finish(pad, color)
    cursor.finish_area()
    cursor.outset(pad)
    primitive.rectangle(color)
end

return background
