-- An example menu to figure out what the hell I'm doing

local cursor = require("ui.cursor")
-- local output = require("ui.cursor.output")
local primitive = require("ui.primitive")
local id = require("ui.id_table")()
local button = require("ui.element.button")
local icon_button = require("ui.element.icon_button")
local numeric_input = require("ui.element.numeric_input")
local slider = require("ui.element.slider")
local switch = require("ui.element.switch")
local theme = require("ui.theme")
local toggle = require("ui.element.toggle")
local toggle_hex = require("ui.element.toggle_hex")
local draw_queue = require("ui.draw_queue")
local element = require("ui.element")
local text = require("ui.text")
local mask = require("ui.mask")

local sample_text = [[
Atque et cumque enim fugiat numquam commodi.
Velit iste sit aut inventore numquam.
Ducimus voluptas asperiores rerum.
]]

return function()
    cursor.auto_reshape = true
    -- primitive.rectangle_outline(nil, 10)

    -- cursor.anchor_x = 0
    -- cursor.anchor_y = 0
    -- cursor.x = 40
    -- cursor.y = 40
    -- cursor.width = 20
    -- cursor.height = 20

    -- for x, y in cursor.grid(3, 3, 10) do
    --     primitive.rectangle()
    -- end

    -- cursor.shift_down()

    -- button(id.button1)


    cursor.x = 60
    cursor.y = 10
    cursor.width = 75
    cursor.height = 1000

    mask.push()

    cursor.x = 60
    cursor.y = 10
    cursor.width = 150

    -- primitive.rectangle(theme.red, "line")
    numeric_input(id.numeric, -100, 100, 5, "X = %.2f")
    if id.numeric.clicked then
        print("numeric_input clicked")
    end
    -- primitive.rectangle(theme.green, "line")

    cursor.shift_down(10)
    slider(id.slider, 0, 100, 101)
    cursor.shift_down(10)
    primitive.label(string.format("%d%%", id.slider.value), 16)
    cursor.shift_down(10)

    cursor.width = 150
    slider(id.slider2, 0, 10, 11, true)
    cursor.shift_down(10)
    primitive.label(string.format("%d/10", id.slider2.value), 16)
    cursor.shift_down(10)

    cursor.width = 150
    switch(id.switch, "a", "b", "c", "d", "e")

    mask.pop()

    -- toggles
    cursor.x = 10
    cursor.y = 10
    toggle(id.toggle)
    cursor.shift_down(10)
    toggle_hex(id.toggle_hex)
    cursor.shift_down(10)

    -- array and combining
    cursor.width = 20
    cursor.height = 20
    cursor.v_array(10, 10)

    cursor.pop()
    primitive.rectangle(theme.white)

    cursor.pop()
    cursor.combine()
    primitive.rectangle(theme.white)

    cursor.pop()
    cursor.drop()
    cursor.combine()
    primitive.rectangle(theme.white)

    cursor.pop()
    cursor.drop()
    cursor.drop()
    cursor.combine()
    primitive.rectangle(theme.white)

    -- button
    cursor.x = 260
    cursor.y = 10
    cursor.height = 40
    cursor.width = 200
    button(id.button, "hello world")

    -- Text
    cursor.x = 300
    cursor.y = 100
    cursor.width = 400
    cursor.height = 200
    text.wrap_text = false
    text.align = "left"

    cursor.change_anchor(0)

    primitive.rectangle({ 1, 0, 0, 1 }, "line")
    primitive.label(sample_text, nil, "left")
    primitive.rectangle({ 0, 1, 0, 1 }, "line")

end
