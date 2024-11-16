local cursor = require("ui.cursor")
local events = require("ui.events")
local draw_queue = require("ui.draw_queue")
local mouse = require("ui.mouse")
local typing = require("ui.typing")
local sensor = require("ui.sensor")

local ui = {
    -- this is set using an environment variable, changing it here will do nothing
    scale = 1,
}

---Push a love event to the event sequence.
---All love events should be pushed at the very beginning of a frame.
ui.push_event = events.add

---Grid to show screen and scaled coordinate systems
local debug_grid = tonumber(os.getenv("GRID"))

--[[
    UI update process

    1 frame
    [unordered events] [ordered event execution] [update state changes]

    unordered events
    - add events to the draw_queue
    - reservations and groups can be used to add events out of order

    ordered event execution
    - draw all objects in order
    - perform secondhand calculations that require ordered execution

    update state changes
    - mouse click z-ordering requires in order execution
    - these won't be seen until the next frame
]]

---reset ui state and set scale
function ui.start()
    -- The red grid shows screen space
    if debug_grid then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 0, 0, 0.2)

        local width, height = love.graphics.getDimensions()

        local x = 0
        while x < width do
            love.graphics.line(x, 0, x, height)
            x = x + debug_grid
        end
        x = width
        love.graphics.line(x, 0, x, height)

        local y = 0
        while y < height do
            love.graphics.line(0, y, width, y)
            y = y + debug_grid
        end
        y = height
        love.graphics.line(0, y, width, y)
    end

    -- scale immediately so that screen space positions can be accounted for in any transforms and inverseTransforms
    love.graphics.push()
    love.graphics.scale(ui.scale)
    cursor.reset()

    ---The green grid shows scaled space.
    ---This is where drawn graphics end up, but not everything is affected by graphics transforms.
    if debug_grid then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0, 1, 0, 0.2)

        local width, height = love.graphics.getDimensions()

        local x = 0
        while x < width do
            love.graphics.line(x, 0, x, height)
            x = x + debug_grid
        end
        x = width
        love.graphics.line(x, 0, x, height)

        local y = 0
        while y < height do
            love.graphics.line(0, y, width, y)
            y = y + debug_grid
        end
        y = height
        love.graphics.line(0, y, width, y)

        -- Show scaled mouse position
        x, y = love.mouse.getPosition()
        love.graphics.transformPoint(x, y)
        love.graphics.circle("line", x, y, 4)
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

    -- draw in order
    draw_queue.draw()

    -- do z-ordered mouse intersection checks
    mouse.update()
    sensor.finish()
    typing.update()

    -- undo scaling
    love.graphics.pop()

    -- clean up
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
