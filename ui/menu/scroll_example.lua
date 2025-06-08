local scroll = require("ui.element.scroll")
local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons

local button = require("ui.element.button")

return function()
    cursor.auto_reshape = true
    cursor.x = 50
    cursor.y = 50
    cursor.width = 150
    cursor.height = 150

    if scroll.start(id.scroll) then
        cursor.begin_area()

        cursor.x = 55
        cursor.y = 55
        cursor.width = 40
        cursor.height = 40

        local n, m = 8, 10

        cursor.v_array(n, 10)
        for i = 1, n do
            cursor.pop()
            cursor.h_array(m, 10)
            for j = 1, m do
                cursor.pop()
                button(string.format("%d", (i-1) * m + j), 16)
            end
        end

        cursor.end_area()
        cursor.outset(5)
        scroll.finish(id.scroll)
    end
end
