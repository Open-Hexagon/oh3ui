-- An example menu to figure out what the hell I'm doing

local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local scroll = require("ui.element.scroll")
local mask = require("ui.mask")
local kb_nav = require("ui.control.keyboard_navigation")
local wmode = kb_nav.wrapping_mode

-- Elements
local button = require("ui.element.button")
local cycle_button = require("ui.element.cycle_button")
local icon_button = require("ui.element.icon_button")
local icon_cycle_button = require("ui.element.icon_cycle_button")
local numeric_input = require("ui.element.numeric_input")
local slider = require("ui.element.slider")
local switch = require("ui.element.switch")
local toggle = require("ui.element.toggle")
local toggle_hex = require("ui.element.toggle_hex")

local sample_text = [[
Atque et cumque enim fugiat numquam commodi.
Velit iste sit aut inventore numquam.
Ducimus voluptas asperiores rerum.
]]

return function()
    kb_nav.set_wrapping(wmode.list, wmode.vertical)
    kb_nav.set_page_length(2)

    cursor.auto_reshape = true
    cursor.x = 60
    cursor.y = 10
    cursor.width = 150

    kb_nav.make_cell()
    kb_nav.grid_cell(1, 1)
    kb_nav.inject(id.numeric)
    numeric_input(id.numeric, -100, 100, 5, "X = %.2f")
    if id.numeric.clicked then
        print("numeric_input clicked")
    end
    cursor.shift_down(10)

    -- Slider
    kb_nav.make_cell()
    kb_nav.grid_cell(1, 2)
    kb_nav.inject(id.slider)
    slider(id.slider, 0, 100, 101)
    cursor.shift_down(10)
    primitive.label(string.format("%d%%", id.slider.value), 16, "left", false)
    cursor.shift_down(10)

    -- Coarse Slider
    cursor.width = 150
    kb_nav.make_cell()
    kb_nav.grid_cell(1, 3)
    kb_nav.inject(id.slider_coarse)
    slider(id.slider_coarse, 0, 10, 11, true)
    cursor.shift_down(10)
    primitive.label(string.format("%d/10", id.slider_coarse.value), 16, "left", false)
    cursor.shift_down(10)

    -- Switch
    cursor.width = 150
    kb_nav.make_cell()
    kb_nav.grid_cell(1, 4)
    kb_nav.inject(id.switch)
    switch(id.switch, "a", "b", "c")
    cursor.shift_down(10)

    kb_nav.make_cell()
    kb_nav.grid_cell(1, 5)
    kb_nav.inject(id.button)
    button(id.button, "button", 16)
    cursor.shift_down(10)

    kb_nav.make_cell()
    kb_nav.grid_cell(1, 6)
    kb_nav.inject(id.cycle_button)
    cycle_button(id.cycle_button, 16, "square", "triangle", "hexagon")
    cursor.shift_down(10)

    -- Toggles
    kb_nav.make_cell()
    kb_nav.grid_cell(1, 7)
    kb_nav.inject(id.toggle)

    toggle(id.toggle)
    cursor.shift_down(10)

    kb_nav.make_cell()
    kb_nav.grid_cell(1, 8)
    kb_nav.inject(id.toggle_hex)
    toggle_hex(id.toggle_hex)
    cursor.shift_down(10)

    kb_nav.make_cell()
    kb_nav.grid_cell(1, 9)
    kb_nav.inject(id.icon_button)
    icon_button(id.icon_button, 16, "triangle")
    cursor.shift_down(10)

    kb_nav.make_cell()
    kb_nav.grid_cell(1, 10)
    kb_nav.inject(id.icon_cycle_button)
    icon_cycle_button(id.icon_cycle_button, 16, "square", "dash-square", "check-square")
    cursor.shift_down(10)
end


