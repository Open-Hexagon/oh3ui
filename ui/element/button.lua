local state = require("ui.state")
local theme = require("ui.theme")
local rectangle = require("ui.element.rectangle")
local label = require("ui.element.label")
local area = require("ui.area")
local hover_interaction = require("ui.interaction.hover")

-- don't recreate the table every time
local rectangle_color_overwrite = {}

---make a box sized based on text content that is highlighted when hovered
return function(button_state, text)
    -- process label, which updates area size (area not drawn yet)
    area.start()
    label(text)
    area.set_state_to_bounds()
    area.done()

    -- add a padding of 4 on each side
    state.x = state.x + 4 * (2 * state.anchor.x - 1)
    state.y = state.y + 4 * (2 * state.anchor.y - 1)
    state.width = state.width + 8
    state.height = state.height + 8

    -- save clicked state for later use
    local label_clicked = state.clicked

    -- set rectangle_color_overwrite based on hover timer (it is clamped between 0 and 1)
    button_state.hover_timer = button_state.hover_timer or 0
    for i = 1, 3 do
        rectangle_color_overwrite[i] = button_state.hover_timer * 0.2 + 0.2
    end
    rectangle_color_overwrite[4] = 1

    -- draw rectangle with custom color
    theme.rectangle_color = rectangle_color_overwrite
    rectangle("fill")
    theme.rectangle_color = nil

    -- set clicked state not only if rectangle but also if label was clicked
    state.clicked = label_clicked or state.clicked

    -- update hover timer
    hover_interaction.timer(button_state, love.timer.getDelta() * 10)

    -- draw the area containing the label
    area.draw()
end
