local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local decorator = require("ui.decorator")




---@param text string
return function(state, text)
    cursor.push()


    cursor.pop()
end