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
local text = require("ui.text")
local scroll = require("ui.element.scroll")
local mask = require("ui.mask")
local keyboard_navigation = require("ui.keyboard_navigation")

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

    -- mask.push()
    cursor.apply_translation(40, 0)

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
    switch(id.switch, "a", "b", "c")

    cursor.remove_translation()

    -- mask.pop()

    -- toggles
    cursor.x = 10
    cursor.y = 10
    cursor.apply_translation(40, 30)
    toggle(id.toggle)
    cursor.remove_translation()
    cursor.shift_down(10)
    toggle_hex(id.toggle_hex)
    cursor.shift_down(10)

    -- array and combining
    cursor.width = 20
    cursor.height = 20
    cursor.push() -- (1)
    cursor.h_array(3, 10)
    cursor.pop()
    keyboard_navigation.next_as_escape()
    primitive.rectangle(keyboard_navigation.make_cell() and theme.accent_color or theme.white)
    keyboard_navigation.grid_cell(1, 1)
    cursor.pop()
    primitive.rectangle(keyboard_navigation.make_cell() and theme.accent_color or theme.white)
    -- keyboard_navigation.grid_cell(2, 1)
    cursor.pop()
    primitive.rectangle(keyboard_navigation.make_cell() and theme.accent_color or theme.white)
    keyboard_navigation.grid_cell(3, 1)

    cursor.pop() -- (1)
    cursor.shift_down(10)
    cursor.h_array(3, 10)
    cursor.pop()
    keyboard_navigation.next_as_default()
    primitive.rectangle(keyboard_navigation.make_cell() and theme.accent_color or theme.white)
    keyboard_navigation.grid_cell(1, 2)
    cursor.pop()
    cursor.combine()
    primitive.rectangle(keyboard_navigation.make_cell() and theme.accent_color or theme.white)
    keyboard_navigation.grid_cell(2, 2, 2)

    -- button

    -- draw_queue.reserve()
    -- cursor.begin_area()

    -- problematic

    cursor.x = 260
    cursor.y = 10
    cursor.height = 40
    cursor.width = 200
    button(id.button, "button")

    -- cursor.x = 360
    cursor.y = 30
    -- cursor.shift_down()
    button(id.button2, "button2")

    -- cursor.end_area()
    -- cursor.inset(15)
    -- draw_queue.take_last_reservation()
    -- mask.push()
    -- mask.pop()

    -- Text
    cursor.change_anchor(0)

    cursor.x = 300
    cursor.y = 100
    cursor.width = 200
    cursor.height = 200

    text.wrap_text = false
    text.align = "left"

    primitive.rectangle(theme.white, "line")
    if scroll.start(id.scroll) then
        cursor.begin_area()

        cursor.inset(10)

        cursor.v_split(2, 10)

        cursor.pop()
        primitive.rectangle(theme.red, "line")

        cursor.pop()
        primitive.rectangle(theme.white, "line")

        if scroll.start(id.scroll2) then -- nested scrolls suck for UX but you can do it I guess
            cursor.begin_area()

            cursor.inset(10)
            primitive.rectangle(theme.green, "line")

            cursor.push()

            cursor.shift_down(5)
            slider(id.slider3, 0, 8, 9, true)
            cursor.peek()

            cursor.shift_left(5)
            button(id.button3, "button3")
            cursor.peek()

            cursor.shift_right(5)
            primitive.rectangle(theme.green, "line")
            cursor.peek()

            cursor.drop()

            cursor.put_area()
            cursor.outset(5)
            primitive.rectangle(theme.blue, "line")

            cursor.end_area()
            -- no place operations should happen between end area and scroll finish
            scroll.finish(id.scroll2)
        end

        cursor.shift_down(10)
        numeric_input(id.numeric2, -100, 100, 5, "Y = %.2f")
        cursor.shift_left(10)
        primitive.rectangle(theme.red, "line")

        cursor.put_area()
        cursor.outset(10)
        primitive.rectangle(theme.blue, "line")
        cursor.end_area()
        -- no place operations should happen between end area and scroll finish
        scroll.finish(id.scroll)
    end

    cursor.shift_right(10)
    -- cursor.height = 29
    primitive.rectangle(theme.white, "line")

    -- infinite scrolling
    if scroll.start(id.scroll3) then
        id.scroll3.n = id.scroll3.n or 10
        cursor.begin_area()

        cursor.inset(10)
        cursor.change_anchor(0)
        cursor.height = 20

        -- add items if we're at the bottom and we're not dragging the scrollbars
        if id.scroll3.at_bottom and not id.scroll3.dragging then
            id.scroll3.n = id.scroll3.n + 5
        end

        cursor.auto_reshape = false
        for i = 1, id.scroll3.n do
            primitive.label(tostring(i), 20)
            cursor.shift_down(10)
        end
        cursor.auto_reshape = true

        cursor.end_area()
        cursor.outset(10)
        scroll.finish(id.scroll3)
    end
end
