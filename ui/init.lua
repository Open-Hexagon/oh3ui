local events = require("ui.events")
local draw_queue = require("ui.draw_queue")
local control = require("ui.control")
local settings = require("ui.settings")
local volatile_data = require("ui.shared_data").volatile
local warning = require("ui.warning")
local layers = require("ui.layers")

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

ui.init = layers.init

local function start()
    -- The red grid shows screen space
    -- luacov: disable
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
    -- luacov: enable

    -- scale immediately so that screen space positions can be accounted for in any transforms and inverseTransforms
    love.graphics.push()
    love.graphics.scale(settings.scale)

    ---The green grid shows scaled space.
    ---This is where drawn graphics end up, but not everything is affected by graphics transforms.
    -- luacov: disable
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
    -- luacov: enable
end

local function finish()
    if volatile_data.cursor_index > 0 then
        volatile_data.cursor_index = 0
        volatile_data.cursor_base_index = 0
        warning("cursor stack was not empty")
    end
    if volatile_data.translate_index > 1 then
        volatile_data.translate_index = 1
        volatile_data.translate_base_index = 1
        warning("translation stack was not empty")
    end
    if volatile_data.area_index > 0 then
        volatile_data.area_index = 0
        volatile_data.area_base_index = 0
        warning("area stack was not empty")
    end
    if volatile_data.mask_index > 0 then
        volatile_data.mask_index = 0
        volatile_data.mask_base_index = 0
        warning("not all masks were removed")
    end
    if volatile_data.aeb_index > 0 then
        volatile_data.aeb_index = 0
        volatile_data.aeb_base_index = 0
        warning("an area element wasn't finished")
    end
    if volatile_data.record_stack_index > 0 then
        volatile_data.record_stack_index = 0
        warning("the record stack wasn't empty at the end of frame")
    end

    -- draw in order
    draw_queue.draw()

    -- evaluate control methods
    control.evaluate()

    -- undo scaling
    love.graphics.pop()

    -- clean up
    events.clear()
    love.graphics.setScissor()
end

---reset ui state and set scale
function ui.run()
    start()
    layers.run()
    finish()
end

return ui
