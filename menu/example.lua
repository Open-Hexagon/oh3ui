local ui = require("ui")

local id = ui.new_id_table()
local cursor = ui.cursor
local theme = ui.theme
local draw_by_cursor = ui.draw.by_cursor
local mnav = ui.control.mouse_navigation
local smode = mnav.sensor_mode
local mb = mnav.buttons
local knav = ui.control.keyboard_navigation
local kba = knav.actions
local wmode = knav.wrapping_mode
local settings = ui.settings
local typing = ui.control.typing
local ansi = ui.text.ansi
local search = ui.text.search
local text = ui.text

-- Elements
local button = ui.element.button
local cycle_button = ui.element.cycle_button
local icon_button = ui.element.icon_button
local icon_cycle_button = ui.element.icon_cycle_button
local numeric_input = ui.element.numeric_input
local slider = ui.element.slider
local switch = ui.element.switch
local toggle = ui.element.toggle
local toggle_hex = ui.element.toggle_hex
local checkbox = ui.element.checkbox

local tooltip = ui.decorator.tooltip
local selection_outline = ui.decorator.selection_outline

local scroll_example_menu = require("menu.scroll_example")

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

    cursor.push_translation(50, 50)

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

    knav.set_current_cell_id(0)

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
    knav.make_cell()
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
    button("deselect kb", 16)
    if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
        knav.deselect()
    end
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

    do
        local text_entry_cell = knav.make_cell()
        knav.grid_cell(1, 13)
        local text_entry_sensor = mnav.make_sensor(nil, smode.block)

        draw_by_cursor.rectangle(theme.green, "line")
        if knav.is_selected() then
            selection_outline()
        end

        typing.make_text_entry(id.text_entry, text_entry_sensor, text_entry_cell)
        typing.draw_text_entry(24, "Search")
        cursor.shift_down(10)
    end

    do
        local text_entry_cell2 = knav.make_cell()
        knav.grid_cell(1, 14)
        local text_entry_sensor2 = mnav.make_sensor(nil, smode.block)

        draw_by_cursor.rectangle(theme.green, "line")
        if knav.is_selected() then
            selection_outline()
        end

        typing.make_text_entry(id.text_entry2, text_entry_sensor2, text_entry_cell2, true)
        typing.draw_text_entry(36, "Search2")
        cursor.shift_down(10)
    end

    do
        local matches, score, text = search(id.text_entry.text, id.text_entry2.text, theme.text_color, theme.red)

        draw_by_cursor.label(string.format("matches: %s, score: %d", tostring(matches), score), 16, "left", false)
        cursor.shift_down(10)
        draw_by_cursor.label(text, 20, "left", false)
        cursor.shift_down(10)
    end

    do
        cursor.width = 200
        cursor.height = 20
        knav.make_cell()
        knav.grid_cell(1, 15)
        button("open scroll example", 16)
        if mnav.get_clicked() == mb.left or knav.get_action() == kba.activate then
            ui.layer.push(scroll_example_menu)
        end
    end

    do
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
        cursor.height = 40
        draw_by_cursor.rectangle_outline(theme.yellow, 1)
        draw_by_cursor.label(
            text.replace_icon_sequences(
                "\x1c&debug-full-mono-character-block; X\x1c&square;g \x1c&debug-full-mono-character-block;\n\x1c&square;XXXX"
            ),
            40,
            align,
            id.toggle.on
        )
        draw_by_cursor.rectangle_inline(theme.green, 1)
    end

    cursor.pop_translation()
end
