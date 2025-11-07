-- An example menu to figure out what the hell I'm doing

local cursor = require("ui.cursor")
local id = require("ui.id_table")()
local theme = require("ui.theme")
local draw_by_cursor = require("ui.draw_queue").by_cursor
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local wmode = knav.wrapping_mode
local settings = require("ui.settings")
local typing = require("ui.control.typing")
local layers = require("ui.layers")
local scroll_example_menu = require("ui.menu.scroll_example")
local shared_data = require("ui.shared_data")
local ansi = require("ui.text.ansi")

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
local checkbox = require("ui.element.checkbox")
local tooltip = require("ui.decorator.tooltip").tooltip
local selection_outline_set_location = require("ui.decorator.selection_outline").set_placement

local counter = 0

local colored_text = ansi.colored_text_to_string({
    theme.red,
    "Magnam blanditiis et et perferendis ipsum qui nisi.\n",
    theme.green,
    "Earum voluptatem qui ea amet ea quae est deleniti.\n",
    theme.blue,
    "Tempore dolores ex et iusto.\n",
    theme.yellow,
    "Rerum ducimus tenetur fugit.\n",
})

return function()
    cursor.change_anchor(0.5)
    draw_by_cursor.label(string.format("%02d", counter), 400, "center", false, { 1, 1, 1, 0.1 })
    counter = (counter + 1) % 60
    cursor.change_anchor(0)

    cursor.push_translation(100, 100)

    knav.set_wrapping(wmode.redirect, wmode.vertical)
    knav.set_page_length(2)

    cursor.auto_reshape = true
    cursor.x = 60
    cursor.y = 10
    cursor.width = 150
    cursor.height = 20

    knav.make_cell()
    knav.grid_cell(1, 1)
    numeric_input(id.numeric, -100, 100, 5, 1, "X = %.2f")
    tooltip("right", string.rep("tooltip text", 5, "\n"), 16, "left", nil)
    cursor.shift_down(0)

    -- Slider
    knav.make_cell()
    knav.grid_cell(1, 2)
    slider(id.slider, 100, 500, 401)
    tooltip(
        "right",
        [[
Magnam blanditiis et et perferendis ipsum qui nisi.
Earum voluptatem qui ea amet ea quae est deleniti.
Tempore dolores ex et iusto.
Rerum ducimus tenetur fugit.
]],
        16,
        "center",
        250
    )
    cursor.shift_down(10)
    draw_by_cursor.label(string.format("%d%%", id.slider.value), 16, "left", false)
    cursor.shift_down(10)

    knav.change_current_cell(0)

    cursor.width = 150
    slider(id.slider_anchor_x, 0, 1, 101)
    cursor.shift_down(10)

    slider(id.slider_anchor_y, 0, 1, 101)
    cursor.shift_down(10)

    -- Coarse Slider
    cursor.width = 150
    knav.make_cell()
    knav.grid_cell(1, 3)
    slider(id.slider_coarse, 1, 3, 5, true)
    if knav.get_action() == kba.activate then
        settings.scale = id.slider_coarse.value
    end
    cursor.shift_down(10)

    draw_by_cursor.label(string.format("UI Scale: %.1f", id.slider_coarse.value), 16, "left", false)
    cursor.shift_down(10)

    cursor.width = 150
    knav.make_cell("default")
    knav.grid_cell(1, 4)
    button("Apply UI Scale", 16)
    if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
        settings.scale = id.slider_coarse.value
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

    cursor.width = 200
    cursor.height = 50

    local text_entry_cell = knav.make_cell("default")
    knav.grid_cell(1, 13)
    local text_entry_sensor = mnav.make_sensor(nil, smode.block)

    draw_by_cursor.rectangle(theme.green, "line")
    if knav.is_selected() then
        selection_outline_set_location()
    end

    typing.make_text_entry(id.text_entry, text_entry_sensor, text_entry_cell)
    typing.draw_text_entry(24, "Search")
    cursor.shift_down(10)

    local text_entry_cell2 = knav.make_cell()
    knav.grid_cell(1, 14)
    local text_entry_sensor2 = mnav.make_sensor(nil, smode.block)

    draw_by_cursor.rectangle(theme.green, "line")
    if knav.is_selected() then
        selection_outline_set_location()
    end

    typing.make_text_entry(id.text_entry2, text_entry_sensor2, text_entry_cell2)

    typing.draw_text_entry(36, "Search2")

    cursor.shift_down(10)

    cursor.width = 150
    cursor.height = 20
    knav.make_cell()
    knav.grid_cell(1, 15)
    button("open scroll example", 16)
    if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
        layers.push(scroll_example_menu)
    end

    local align
    if id.switch.position == 1 then
        align = "left"
    elseif id.switch.position == 2 then
        align = "center"
    else
        align = "right"
    end

    cursor.shift_down(40)
    cursor.width = id.slider.value
    cursor.change_anchor(id.slider_anchor_x.value, id.slider_anchor_y.value)

    draw_by_cursor.label(colored_text, 16, align, id.toggle.on)

    cursor.pop_translation()
end
