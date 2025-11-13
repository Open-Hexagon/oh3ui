local scroll = require("ui.area.element.scroll")
local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local draw_by_cursor = require("ui.draw_queue").by_cursor
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local wmode = knav.wrapping_mode
local layers = require("ui.layers")
local kba = knav.actions
local collapse = require("ui.area.element.collapse")

local background = require("ui.area.element.background")

local button = require("ui.element.button")

return function()
    draw_by_cursor.rectangle({ 0, 0, 0, 0.8 })
    knav.set_wrapping(wmode.tab, wmode.vertical)

    cursor.auto_reshape = true
    cursor.x = 200
    cursor.y = 50
    cursor.width = 200
    cursor.height = 200

    draw_by_cursor.rectangle(theme.green, "line")
    scroll.start(id.scroll2)
    background.start()
    do
        cursor.x = cursor.x + 10
        cursor.y = cursor.y + 10
        cursor.width = 150
        cursor.height = 150

        draw_by_cursor.rectangle(theme.green, "line")
        scroll.start(id.scroll)
        background.start()
        do
            cursor.x = cursor.x + 10
            cursor.y = cursor.y + 10
            cursor.width = 40
            cursor.height = 40

            local n, m = 5, 5

            cursor.v_array(n, 0)
            for i = 1, n do
                cursor.pop()
                cursor.h_array(m, 0)
                for j = 1, m do
                    cursor.pop()

                    knav.make_cell()
                    knav.grid_cell(j, i)
                    button(string.format("a%d", (i - 1) * m + j), 16)
                end
            end
        end
        background.finish(10, theme.blue)
        local at_left, at_top, at_right, at_bottom = scroll.finish(0)

        knav.fill_grid(knav.op_cell.tab, 6, 1, 1, 5)
        cursor.push()
        cursor.shift_right(10)

        draw_by_cursor.rectangle(theme.green, "line")
        scroll.start(id.scroll3)
        background.start()
        do
            cursor.x = cursor.x + 10
            cursor.y = cursor.y + 10
            cursor.width = 40
            cursor.height = 40

            local n, m = 5, 5

            cursor.v_array(n, 0)
            for i = 1, n do
                cursor.pop()
                cursor.h_array(m, 0)
                for j = 1, m do
                    cursor.pop()

                    knav.make_cell()
                    knav.grid_cell(6 + j, i)
                    button(string.format("b%d", (i - 1) * m + j), 16)
                end
            end
        end
        background.finish(10, theme.blue)
        scroll.finish(0)

        cursor.pop()
        cursor.shift_down(10)

        draw_by_cursor.label(
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

        local grid_i = 11
        do
            cursor.auto_reshape = false
            cursor.width = 170
            cursor.height = 20

            knav.make_cell()
            knav.grid_cell(1, grid_i)
            grid_i = grid_i + 1
            button("a", 16)
            cursor.shift_down(0)

            knav.make_cell()
            knav.grid_cell(1, grid_i)
            grid_i = grid_i + 1
            button("b", 16)
            cursor.shift_down(0)

            knav.set_current_cell_id(0)
            button("collapse", 16)
            cursor.shift_down(0)

            cursor.h_squeeze(10)
            collapse.start(id.collapse, "topleft", "top", false)
            do
                for i = 1, 5 do
                    knav.make_cell()
                    knav.grid_cell(1, grid_i)
                    grid_i = grid_i + 1
                    button(tostring(i), 16)
                    cursor.shift_down(0)
                end
                knav.set_current_cell_id(0)
                button("collapse2", 16)
                cursor.shift_down(0)
                cursor.h_squeeze(10)
                collapse.start(id.collapse2, "topleft", "top", false)
                do
                    for i = 1, 5 do
                        knav.make_cell()
                        knav.grid_cell(1, grid_i)
                        grid_i = grid_i + 1
                        button(tostring(i + 10), 16)
                        cursor.shift_down(0)
                    end
                end
                collapse.finish()
                cursor.h_squeeze(-10)
            end
            collapse.finish()
            cursor.h_squeeze(-10)

            cursor.change_anchor(0)
            cursor.shift_down(0)
            cursor.height = 20

            knav.make_cell()
            knav.grid_cell(1, grid_i)
            grid_i = grid_i + 1
            button("d", 16)
            cursor.shift_down(0)

            knav.make_cell()
            knav.grid_cell(1, grid_i)
            grid_i = grid_i + 1
            button("e", 16)
            cursor.shift_down(0)

            knav.make_cell()
            knav.grid_cell(1, grid_i)
            grid_i = grid_i + 1
            button("f", 16)
            cursor.shift_down(10)
        end

        knav.make_cell()
        knav.grid_cell(1, grid_i)
        grid_i = grid_i + 1
        cursor.height = 25
        button("back", 16)

        if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
            layers.pop()
        end
    end
    background.finish(10, theme.red)
    scroll.finish(0)
end
