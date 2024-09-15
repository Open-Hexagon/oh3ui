local draw_queue = require("ui.draw_queue")
local cursor = require("ui.cursor")
local edge = cursor.edge
local clickbox = require("ui.element.clickbox")
local theme = require("ui.theme")

return function(state, text)
    cursor.place()
    clickbox(state)

    draw_queue.rectangle(
        "fill",
        edge.left,
        edge.top,
        edge.right,
        edge.bottom,
        state.primed and theme.button_background_highlight or theme.button_background,
        3,
        3
    )
    cursor.inset(0.5)
    cursor.place()
    draw_queue.rectangle(
        "line",
        edge.left,
        edge.top,
        edge.right,
        edge.bottom,
        cursor.mouse_intersect.hovering and theme.button_border_highlight or theme.button_border,
        3,
        3
    )

    return state.clicked
end
