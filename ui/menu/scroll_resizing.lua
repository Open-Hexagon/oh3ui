local scroll = require("ui.area.element.scroll")
local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local wmode = knav.wrapping_mode
local layers = require("ui.layers")
local kba = knav.actions
local button = require("ui.element.button")

local collapsed = false

-- TODO, scrolling doesn't handle shrinking elements well

return function()
    cursor.auto_reshape = true

    cursor.x = 10
    cursor.y = 10
    cursor.width = 200
    cursor.height = 200

    primitive.rectangle(theme.red, "line", 2)
    scroll.start(id.scroll)

    if mnav.clicked then
        collapsed = not collapsed
    end
    if collapsed then
        cursor.height = 300
    else
        cursor.height = 400
    end

    primitive.rectangle(theme.green, "line", 2)

    scroll.finish(0)
end
