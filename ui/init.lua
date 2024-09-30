local cursor = require("ui.cursor")
local events = require("ui.events")
local draw_queue = require("ui.draw_queue")
-- local scroll_interaction = require("ui.interaction.scroll")
-- local text_interaction = require("ui.interaction.text")
-- local keyboard_navigation = require("ui.keyboard_navigation")

local ui = {
    -- this is set using an environment variable, changing it here will do nothing
    scale = 1,
}

---Push a love event to the event sequence.
---All love events should be pushed at the very beginning of a frame.
---@param name string
---@param ... unknown
function ui.push_event(name, ...)
    events.add(name, ...)
end

---Broadcasters are modules that need to be updated at the beginning of each frame.
---Their outputs should remain constant during a frame.
local broadcasters = {
    require("ui.interaction.mouse"),
}

---reset ui state and set scale
function ui.start()
    cursor.reset()
    for i = 1, #broadcasters do
        broadcasters[i].update()
    end
    -- scroll_interaction.reset()
    -- love.keyboard.setKeyRepeat(text_interaction.is_interacting_with_text)
    -- love.keyboard.setTextInput(text_interaction.is_interacting_with_text)
    -- text_interaction.reset()
    -- keyboard_navigation.reset()
end

---Do ui finalization and cleanup
function ui.finish()
    -- keyboard_navigation.run()
    love.graphics.push()
    love.graphics.scale(ui.scale)
    draw_queue.draw()
    love.graphics.pop()

    events.clear()
    cursor.finish()
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
