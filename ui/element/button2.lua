local cursor = require("ui.cursor")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local clickbox = require("ui.element.clickbox")
local rectangle = require("ui.primitive").rectangle
local label = require("ui.element.label")

return function(state, text, icon)
    cursor.place()
    clickbox(state)

    cursor.push()

    draw_queue.reserve() -- for background
    draw_queue.reserve() -- for outline


    draw_queue.take_last_reservation()
    rectangle("line", cursor.mouse_intersect.hovering and theme.button_border_highlight or theme.button_border)
    draw_queue.take_last_reservation()
    rectangle("fill", state.holding and theme.button_background_highlight or theme.button_background)

    cursor.pop()
    return state.clicked
end
