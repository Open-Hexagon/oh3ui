local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local button = require("ui.element.button")
local cursor = require("ui.cursor")

return function()
    cursor.auto_reshape = true
    cursor.x = 60
    cursor.y = 10
    cursor.width = 150
    cursor.height = 20

    knav.make_cell("default")
    button("default", 16)

    cursor.shift_down(10)

    knav.make_cell("escape")
    button("escape", 16)

    cursor.shift_down(10)

    knav.make_cell()
    knav.grid_cell(1, 1)
    button("t", 16)
end
