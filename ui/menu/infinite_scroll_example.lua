local state = require("ui.state")
local rectangle = require("ui.element.rectangle")
local label = require("ui.element.label")
local scroll = require("ui.area.scroll")

local scroll_state = {}
local max_amount = 0

return function()
    local area_height = 500
    local box_height = 100
    state.height = box_height - 10  -- 10 padding
    scroll.start(scroll_state, "vertical", 500)
    local amount = math.floor(scroll_state.position / box_height + area_height / box_height + 2)
    max_amount = math.max(max_amount, amount)
    local start_y = state.y
    state.allow_automatic_resizing = false  -- prevent labels from changing size of further elements
    for i in scroll.elements_in_view(max_amount) do
        state.y = start_y + (i - 1) * box_height
        rectangle()
        label(tostring(i))
    end
    state.allow_automatic_resizing = true
    scroll.done()
end
