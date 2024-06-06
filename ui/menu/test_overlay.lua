local state = require("ui.state")
local background_area = require("ui.area.background")
local rectangle = require("ui.element.rectangle")
local layers = require("ui.layers")
local theme = require("ui.theme")
local area = require("ui.area")
local ui = require("ui")

local background_color = { 0, 0, 0, 0.5 }

return function()
    background_area.start()

    local max_width = ui.get_width() / 2
    state.width = 100
    state.height = 50
    state.x = 20
    state.y = 20
    for i = 1, 10 do
        if state.x + state.width + 10 > max_width then
            state.y = state.y + state.height + 10
            state.x = 20
        end
        rectangle()
        if state.clicked then
            print(i .. ". wrapped rectangle clicked")
            if i == 1 then
                layers.pop()
            end
        end
        state.x = state.x + state.width + 10
    end

    -- add some padding around the area before drawing
    local bounds = area.get_bounds()
    bounds.left = bounds.left - 4
    bounds.top = bounds.top - 4
    bounds.right = bounds.right + 4
    bounds.bottom = bounds.bottom + 4

    theme.rectangle_color = background_color
    background_area.done()
    theme.rectangle_color = nil
end
