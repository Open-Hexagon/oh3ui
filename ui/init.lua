local state = require("ui.state")
local events = require("ui.events")
local scroll_interaction = require("ui.interaction.scroll")
local draw_queue = require("ui.draw_queue")
local text_interaction = require("ui.interaction.text")
local keyboard_navigation = require("ui.keyboard_navigation")

local ui = {
    scale = 1,
}

---Push a love event to the event sequence.
---This is done at the very beginning of a frame
---@param name string
---@param ... unknown
function ui.push_event(name, ...)
    events.add(name, ...)
end

-- Interactions that need an update at the beginning of the frame
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
    love.keyboard.setKeyRepeat(text_interaction.is_interacting_with_text)
    love.keyboard.setTextInput(text_interaction.is_interacting_with_text)
    text_interaction.reset()
    keyboard_navigation.reset()
end

---undo transformations
function ui.done()
    keyboard_navigation.run()
    events.clear()
    love.graphics.pop()
    draw_queue.draw()
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
