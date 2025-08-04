local cursor = require("ui.cursor")
local events = require("ui.events")
local draw_queue = require("ui.draw_queue")
local control = require("ui.control")
local settings = require("ui.settings")

local ui = {}

---Push a love event to the event sequence.
---All love events should be pushed at the very beginning of a frame.
ui.push_event = events.add

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
    if settings.debug_grid then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 0, 0, 0.2)

        local width, height = love.graphics.getDimensions()

        local x = 0
        while x < width do
            love.graphics.line(x, 0, x, height)
            x = x + settings.debug_grid
        end
        x = width
        love.graphics.line(x, 0, x, height)

        local y = 0
        while y < height do
            love.graphics.line(0, y, width, y)
            y = y + settings.debug_grid
        end
        y = height
        love.graphics.line(0, y, width, y)
    end

    -- scale immediately so that screen space positions can be accounted for in any transforms and inverseTransforms
    love.graphics.push()
    love.graphics.scale(settings.scale)
    cursor.reset()

    ---The green grid shows scaled space.
    ---This is where drawn graphics end up, but not everything is affected by graphics transforms.
    if settings.debug_grid then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0, 1, 0, 0.2)

        local width, height = love.graphics.getDimensions()

        local x = 0
        while x < width do
            love.graphics.line(x, 0, x, height)
            x = x + settings.debug_grid
        end
        x = width
        love.graphics.line(x, 0, x, height)

        local y = 0
        while y < height do
            love.graphics.line(0, y, width, y)
            y = y + settings.debug_grid
        end
        y = height
        love.graphics.line(0, y, width, y)

        -- Show scaled mouse position
        x, y = love.mouse.getPosition()
        love.graphics.transformPoint(x, y)
        love.graphics.circle("line", x, y, 4)
    end
end

---Do ui finalization and cleanup
function ui.finish()
    -- draw in order
    draw_queue.draw()

    -- evaluate control methods
    control.evaluate()

    -- undo scaling
    love.graphics.pop()

    -- clean up
    events.clear()
    cursor.finish()

    -- TODO: massage the volatile data so it's ready for the next frame.
end

---get the width of the ui adjusted for scale
---@return number
function ui.get_width()
    return love.graphics.getWidth() / settings.scale
end

---get the height of the ui adjusted for scale
---@return number
function ui.get_height()
    return love.graphics.getHeight() / settings.scale
end

return ui
