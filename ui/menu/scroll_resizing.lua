local scroll = require("ui.area.element.scroll")
local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local draw_by_cursor = require("ui.draw_queue").by_cursor
local mnav = require("ui.control.mouse_navigation")

local collapsed = false

-- TODO, scrolling doesn't handle shrinking elements well

return function()
    cursor.auto_reshape = true

    cursor.x = 10
    cursor.y = 10
    cursor.width = 200
    cursor.height = 200

    draw_by_cursor.rectangle(theme.red, "line", 2)
    scroll.start(id.scroll)

    if mnav.clicked then
        collapsed = not collapsed
    end
    if collapsed then
        cursor.height = 300
    else
        cursor.height = 400
    end

    draw_by_cursor.rectangle(theme.green, "line", 2)

    scroll.finish(0)
end
