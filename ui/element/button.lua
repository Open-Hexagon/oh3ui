local cursor = require("ui.cursor")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local clickbox = require("ui.element.clickbox")
local primitive = require("ui.primitive")

return function(state, text, icon)
    cursor.place()
    clickbox(state)

    draw_queue.begin_group()

    draw_queue.reserve() -- for background
    draw_queue.reserve() -- for outline

    draw_queue.take_last_reservation()
    primitive.outline(cursor.mouse_intersect.hovering and theme.button_border_highlight or theme.button_border)
    draw_queue.take_last_reservation()
    primitive.rectangle("fill", state.holding and theme.button_background_highlight or theme.button_background)

    draw_queue.end_group()
    return state.clicked
end
