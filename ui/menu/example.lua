-- An example menu to figure out what the hell I'm doing
-- Start from first principles

local cursor = require("ui.cursor")
-- local output = require("ui.cursor.output")
local primitive = require("ui.primitive")
local id = require("ui.id_table")()
local button = require("ui.element.button")
-- local background = require("ui.area.background")
-- local theme = require("ui.theme")
local toggle = require("ui.element.toggle")
local toggle_hex = require("ui.element.toggle_hex")
local draw_queue = require("ui.draw_queue")

local sample_text = [[
Atque et cumque enim fugiat numquam commodi.
Velit iste sit aut inventore numquam.
Ducimus voluptas asperiores rerum.
]]

return function()
    primitive.rectangle_outline(nil, 10)

    cursor.anchor_x = 0
    cursor.anchor_y = 0
    cursor.x = 40
    cursor.y = 40
    cursor.width = 20
    cursor.height = 20

    for x, y in cursor.grid(3, 3, 10) do
        primitive.rectangle()
    end

    cursor.shift_down()

    button(id.button1)

    cursor.shift_right(0, 2)

    cursor.width = 800
    cursor.height = 100

    for x, y in cursor.subdivide(3, 1, 10) do
        -- primitive.rectangle()
        button(id[string.format("button%d%d", x, y)], "hello world")
    end

    cursor.x = 10
    cursor.y = 10
    toggle(id.toggle)
    cursor.shift_down(10)
    toggle_hex(id.toggle_hex)

    cursor.shift_down(10)
    cursor.shift_right(10)

    primitive.rectangle({ 1, 0, 0, 1 }, "line")
    primitive.icon("archive")
    primitive.rectangle({ 0, 1, 0, 1 }, "line")

    cursor.x = 400
    cursor.y = 300
    cursor.width = 200
    cursor.height = 200
    cursor.wrap_text = false
    cursor.change_anchor(1, 0.5)

    primitive.rectangle({ 1, 0, 0, 1 }, "line")
    primitive.label(sample_text)
    primitive.rectangle({ 0, 1, 0, 1 }, "line")

    -- cursor.y = 500
    -- cursor.width = 100
    -- cursor.height = 40

    -- button2(id.btn2, "hello")

    -- if id.btn2.clicked then
    --     print("clicked", id.btn2.clicked)
    -- end

    -- draw_queue.push_scissor(0, 0, 60, 60)
    -- draw_queue.rectangle("fill", 0, 0, 100, 100, { 1, 0, 0, 1 })
    -- draw_queue.push_scissor(30, 30, 90, 90)
    -- draw_queue.rectangle("fill", 0, 0, 100, 100, { 0, 1, 0, 1 })

    -- draw_queue.pop_scissor()
    -- draw_queue.pop_scissor()

    -- draw_queue.reserve()
    -- draw_queue.next_takes_last_reservation()
    -- draw_queue.rectangle("fill", 30, 30, 120, 120, {0, 0, 1, 1})
end
