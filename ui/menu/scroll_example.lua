local scroll = require("ui.element.area.scroll")
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

local background = require("ui.element.area.background")

local button = require("ui.element.button")

return function()
    primitive.rectangle({ 0, 0, 0, 0.8 })
    knav.set_wrapping(wmode.tab, wmode.vertical)

    cursor.auto_reshape = true
    cursor.x = 200
    cursor.y = 50
    cursor.width = 170
    cursor.height = 200

    scroll.start(id.scroll2)
    background.start()
    do
        cursor.x = cursor.x + 10
        cursor.y = cursor.y + 10
        cursor.width = 150
        cursor.height = 150

        scroll.start(id.scroll)
        background.start()
        do
            cursor.x = cursor.x + 10
            cursor.y = cursor.y + 10
            cursor.width = 40
            cursor.height = 40

            local n, m = 5, 5

            cursor.v_array(n, 10)
            for i = 1, n do
                cursor.pop()
                cursor.h_array(m, 10)
                for j = 1, m do
                    cursor.pop()

                    knav.make_cell()
                    knav.grid_cell(j, i)
                    button(string.format("a%d", (i - 1) * m + j), 16)
                end
            end
        end
        background.finish(5, theme.blue)
        local at_left, at_top, at_right, at_bottom = scroll.finish(0)

        knav.fill_grid(knav.op_cell.tab, 6, 1, 1, 5)
        cursor.push()
        cursor.shift_right(10)

        scroll.start(id.scroll3)
        background.start()
        do
            cursor.x = cursor.x + 10
            cursor.y = cursor.y + 10
            cursor.width = 40
            cursor.height = 40

            local n, m = 5, 5

            cursor.v_array(n, 10)
            for i = 1, n do
                cursor.pop()
                cursor.h_array(m, 10)
                for j = 1, m do
                    cursor.pop()

                    knav.make_cell()
                    knav.grid_cell(6 + j, i)
                    button(string.format("b%d", (i - 1) * m + j), 16)
                end
            end
        end
        background.finish(5, theme.blue)
        scroll.finish(0)

        cursor.pop()
        cursor.shift_down(10)

        primitive.label(
            string.format(
                "at_left: %s\nat_top: %s\nat_right: %s\nat_bottom: %s",
                tostring(at_left),
                tostring(at_top),
                tostring(at_right),
                tostring(at_bottom)
            ),
            16,
            "left",
            false
        )

        cursor.shift_down(10)

        knav.make_cell()
        knav.grid_cell(1, 11)
        cursor.height = 25
        button("back", 16)

        if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
            layers.pop()
        end
    end
    background.finish(5, theme.red)
    scroll.finish(0)
    cursor.shift_down()

    primitive.rectangle(theme.green, "line", 4)

    -- empty scrolls do nothing but still revert the cursor when finished
    scroll.start(id.scroll4)
    cursor.shift_right()
    scroll.finish(0)

    primitive.rectangle(theme.red, "line")
end
