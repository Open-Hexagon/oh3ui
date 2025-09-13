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

    cursor.auto_reshape = true
    cursor.x = 50
    cursor.y = 50
    cursor.width = 150
    cursor.height = 150

    cursor.apply_translation(100, 0)

    knav.set_wrapping(wmode.tab, wmode.vertical)

    if scroll.start(id.scroll) then
        background.start()

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

                knav.make_cell()
                knav.grid_cell(j, i)
                button(string.format("%d", (i - 1) * m + j), 16)
            end
        end

        background.finish(0, theme.blue)

        scroll.finish(id.scroll, 5)
    end

    cursor.remove_translation()

    cursor.shift_down(10)

    primitive.label(
        string.format(
            "at_left: %s\nat_top: %s\nat_right: %s\nat_bottom: %s",
            tostring(id.scroll.at_left),
            tostring(id.scroll.at_top),
            tostring(id.scroll.at_right),
            tostring(id.scroll.at_bottom)
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
