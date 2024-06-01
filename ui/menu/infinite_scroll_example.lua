local state = require("ui.state")
local rectangle = require("ui.element.rectangle")
local label = require("ui.element.label")
local scroll = require("ui.area.scroll")

local scroll_state = {}

return function()
    scroll.start(scroll_state, "vertical", 500)
    state.allow_automatic_resizing = false  -- prevent labels from changing size of further elements
    state.height = 90
    local start_y = state.y
    for i in scroll.elements_in_view(100) do
        state.y = start_y + (i - 1) * 100
        rectangle()
        label(tostring(i))
    end
    state.allow_automatic_resizing = true
    scroll.done()
end
