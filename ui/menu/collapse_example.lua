local cursor = require("ui.cursor")
local collapse = require("ui.area.element.collapse")
local id = require("ui.id_table")()
local primitive = require("ui.primitive")
local theme = require("ui.theme")
local button = require("ui.element.button")
local mnav = require("ui.control.mouse_navigation")
local knav = require("ui.control.keyboard_navigation")

return function()
    knav.set_wrapping(knav.wrapping_mode.vertical)
    local grid_i = 1

    cursor.auto_reshape = false
    cursor.x = 200
    cursor.y = 160
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

    knav.change_current_cell(0)
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
        knav.change_current_cell(0)
        button("collapse2", 16)
        cursor.shift_down(0)
        cursor.h_squeeze(10)
        collapse.start(id.collapse2, "topleft", "right", false)
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
    cursor.shift_down(0)
end
