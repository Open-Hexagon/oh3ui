local state = require("ui.state")
local event_queue = require("ui.event_queue")
local scroll_interaction = require("ui.interaction.scroll")
local ui = {
    scale = 1,
}

-- interactions that need an update at the beginning of the frame
-- (this is only required for non-element specific interactions)
local interactions = {
    require("ui.interaction.click"),
}

---reset ui state and set scale
function ui.start()
    state.reset()
    love.graphics.push()
    love.graphics.scale(ui.scale, ui.scale)
    for i = 1, #interactions do
        interactions[i].update()
    end
    scroll_interaction.reset()
end

---make the ui process an event
---@param name string
---@param ... unknown
function ui.process_event(name, ...)
    event_queue.add(name, ...)
end

---undo transformations
function ui.done()
    event_queue.clear()
    love.graphics.pop()
end

---get the width of the ui adjusted for scale
---@return number
function ui.get_width()
    return love.graphics.getWidth() / ui.scale
end

---get the height of the ui adjusted for scale
---@return number
function ui.get_height()
    return love.graphics.getHeight() / ui.scale
end

return ui
