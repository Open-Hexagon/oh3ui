-- An example menu to figure out what the hell I'm doing
-- Start from first principles

local cursor = require("ui.cursor")
-- local output = require("ui.cursor.output")
local primitive = require("ui.primitive")
local id = require("ui.id_table")()
local button = require("ui.element.button")
-- local background = require("ui.area.background")
-- local theme = require("ui.theme")
-- local toggle = require("ui.element.toggle")

return function()
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
    
    cursor.width = 200
    cursor.height = 200

    for x, y in cursor.subdivide(3, 2, 10) do
        -- primitive.rectangle()
        button(id[string.format("button%d%d", x, y)])
    end

    cursor.x = 400
    cursor.y = 300
    -- toggle(id.toggle)
    cursor.width = 300
    cursor.height = 300
    cursor.wrap_text = false
    cursor.reshape_on_placement = true
    cursor.change_anchor(0.5, 1)
    primitive.rectangle("line", { 1, 0, 0, 1 })

    primitive.label([[
Atque et cumque enim fugiat numquam commodi.
Velit iste sit aut inventore numquam.
Ducimus voluptas asperiores rerum.
]])

    primitive.rectangle("line", { 0, 1, 0, 1 })

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
