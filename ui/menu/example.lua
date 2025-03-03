-- An example menu to figure out what the hell I'm doing

local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local wmode = knav.wrapping_mode

-- Elements
-- local scroll = require("ui.element.scroll")
local button = require("ui.element.button")
local cycle_button = require("ui.element.cycle_button")
local icon_button = require("ui.element.icon_button")
local icon_cycle_button = require("ui.element.icon_cycle_button")
local numeric_input = require("ui.element.numeric_input")
local slider = require("ui.element.slider")
local switch = require("ui.element.switch")
local toggle = require("ui.element.toggle")
local toggle_hex = require("ui.element.toggle_hex")
local checkbox = require("ui.element.checkbox")


return function()
    knav.set_wrapping(wmode.list, wmode.vertical)
    knav.set_page_length(2)

    cursor.auto_reshape = true
    cursor.x = 60
    cursor.y = 10
    cursor.width = 150
    cursor.height = 20

    knav.make_cell()
    knav.grid_cell(1, 1)
    numeric_input(id.numeric, -100, 100, 5, "X = %.2f")
    cursor.shift_down(10)

    -- Slider
    knav.make_cell()
    knav.grid_cell(1, 2)
    slider(id.slider, 0, 100, 101)
    cursor.shift_down(10)
    primitive.label(string.format("%d%%", id.slider.value), 16, "left", false)
    cursor.shift_down(10)

    -- Coarse Slider
    cursor.width = 150
    knav.make_cell()
    knav.grid_cell(1, 3)
    slider(id.slider_coarse, 1, 3, 5, true)
    cursor.shift_down(10)
    if knav.get_action() == kba.activate then
        require("ui").scale = id.slider_coarse.value
    end

    primitive.label(string.format("UI Scale: %.1f", id.slider_coarse.value), 16, "left", false)
    cursor.shift_down(10)

    cursor.width = 150
    knav.make_cell("default")
    knav.grid_cell(1, 4)
    button("Apply UI Scale", 16)
    if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
        require("ui").scale = id.slider_coarse.value
    end
    cursor.shift_down(10)


    -- Switch
    cursor.width = 150
    knav.make_cell()
    knav.grid_cell(1, 5)
    switch(id.switch, "a", "b", "c")
    cursor.shift_down(10)

    knav.make_cell()
    knav.grid_cell(1, 6)
    button("button", 16)
    cursor.shift_down(10)

    knav.make_cell()
    knav.grid_cell(1, 7)
    cycle_button(id.cycle_button, 16, "square", "triangle", "hexagon")
    cursor.shift_down(10)

    -- Toggles
    knav.make_cell()
    knav.grid_cell(1, 8)
    toggle(id.toggle)
    cursor.shift_down(10)

    knav.make_cell()
    knav.grid_cell(1, 9)
    toggle_hex(id.toggle_hex)
    cursor.shift_down(10)

    cursor.x = 260
    cursor.y = 10
    cursor.width = 150
    cursor.height = 20

    knav.make_cell()
    knav.grid_cell(1, 10)
    icon_button(16, "triangle")
    cursor.shift_down(10)

    knav.make_cell()
    knav.grid_cell(1, 11)
    icon_cycle_button(id.icon_cycle_button, 16, "square", "dash-square", "check-square")
    cursor.shift_down(10)

    knav.make_cell()
    knav.grid_cell(1, 12)
    checkbox(id.checkbox)
    cursor.shift_down(10)
end


