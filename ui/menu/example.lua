-- An example menu to figure out what the hell I'm doing

local cursor = require("ui.cursor")
-- local output = require("ui.cursor.output")
local primitive = require("ui.primitive")
local id = require("ui.id_table")()
local button = require("ui.element.button")
local icon_button = require("ui.element.icon_button")
local numeric_input = require("ui.element.numeric_input")
-- local background = require("ui.area.background")
-- local theme = require("ui.theme")
local toggle = require("ui.element.toggle")
local toggle_hex = require("ui.element.toggle_hex")
local draw_queue = require("ui.draw_queue")
local element = require("ui.element")
local text = require("ui.text")

local sample_text = [[
Atque et cumque enim fugiat numquam commodi.
Velit iste sit aut inventore numquam.
Ducimus voluptas asperiores rerum.
]]

return function()
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
    cursor.width = 150
    numeric_input(id.numeric, -100, 100, 5, "X = %.2f")
    if id.numeric.clicked then
        print("numeric_input clicked")
    end
    cursor.shift_down(10)

    -- toggles
    cursor.x = 10
    cursor.y = 10
    toggle(id.toggle)
    cursor.shift_down(10)
    toggle_hex(id.toggle_hex)

    cursor.shift_down(10)
    cursor.shift_right(10)

    cursor.height = 40
    cursor.width = 200
    button(id.button, "hello world")

    -- primitive.rectangle({ 1, 0, 0, 1 }, "line")
    -- primitive.icon("archive")
    -- primitive.rectangle({ 0, 1, 0, 1 }, "line")

    -- Text
    cursor.x = 300
    cursor.y = 100
    cursor.width = 400
    cursor.height = 200
    text.wrap_text = false
    text.align = "left"

    cursor.change_anchor(0.5, 0.5)

    primitive.rectangle({ 1, 0, 0, 1 }, "line")
    primitive.label(sample_text, nil, "left")
    primitive.rectangle({ 0, 1, 0, 1 }, "line")
end
