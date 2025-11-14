---ui api endpoints

local events = require("ui.events")
local layers = require("ui.layers")
local settings = require("ui.settings")
local draw_data = require("ui.draw_queue.draw_data")

local function start()
    -- The red grid shows screen space
    -- luacov: disable
    if settings.overlay_grid then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 0, 0, 0.2)

        local width, height = love.graphics.getDimensions()

        local x = 0
        while x < width do
            love.graphics.line(x, 0, x, height)
            x = x + settings.overlay_grid
        end
        x = width
        love.graphics.line(x, 0, x, height)

        local y = 0
        while y < height do
            love.graphics.line(0, y, width, y)
            y = y + settings.overlay_grid
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
    if settings.overlay_grid then
        love.graphics.setLineWidth(2)
        love.graphics.setColor(0, 1, 0, 0.2)

        local width, height = love.graphics.getDimensions()

        local x = 0
        while x < width do
            love.graphics.line(x, 0, x, height)
            x = x + settings.overlay_grid
        end
        x = width
        love.graphics.line(x, 0, x, height)

        local y = 0
        while y < height do
            love.graphics.line(0, y, width, y)
            y = y + settings.overlay_grid
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

local layers_run = layers.run
local draw_queue_draw = require("ui.draw_queue.draw")
local view_request_evaluate = require("ui.area.view_request").evaluate
local control_evaluate = require("ui.control.evaluate")
local selection_outline_reset = require("ui.decorator.element.selection_outline").reset
local events_clear = events.clear

local function finish()
    -- draw in order
    draw_data.bake_translations()
    draw_queue_draw()
    draw_data.reset()

    -- for auto-scrolling with keyboard nav
    view_request_evaluate()

    -- evaluate control methods
    control_evaluate()

    -- undo scaling
    love.graphics.pop()

    -- clean up
    events_clear()
    selection_outline_reset()
end

---Runs the ui. Must be called every frame
local function run()
    start()
    layers_run()
    finish()
end

-- TODO global typing
-- TODO multiple page sizes in one layer
-- TODO on/off function that affect regions of a functions should push and pop instead of setting booleans

local ui = {
    -- only user facing api endpoints should be visible from this table

    draw = require("ui.draw_queue"), --OK
    cursor = require("ui.cursor"), -- OK
    theme = require("ui.theme"), -- OK
    control = require("ui.control"), -- OK

    -- OK
    element = {
        const = require("ui.element_parameters"),
        button = require("ui.element.button"),
        checkbox = require("ui.element.checkbox"),
        cycle_button = require("ui.element.cycle_button"),
        icon_button = require("ui.element.icon_button"),
        icon_cycle_button = require("ui.element.icon_cycle_button"),
        numeric_input = require("ui.element.numeric_input"),
        slider = require("ui.element.slider"),
        switch = require("ui.element.switch"),
        toggle_hex = require("ui.element.toggle_hex"),
        toggle = require("ui.element.toggle"),
    },

    -- OK
    area_element = {
        background = require("ui.area.element.background"),
        collapse = require("ui.area.element.collapse"),
        scroll = require("ui.area.element.scroll"),
    },

    -- OK
    decorator = {
        selection_outline = require("ui.decorator.element.selection_outline").set_placement,
        tooltip = require("ui.decorator.element.tooltip").tooltip,
    },

    element_parameters = require("ui.element_parameters"),

    effect = require("ui.effect"), -- OK
    stack_manager = require("ui.stack_manager"), -- clean_up needs to be taken out
    aeb = require("ui.area.aeb"), -- keepout needs to be made better

    settings = require("ui.settings"), -- OK
    new_id_table = require("ui.id_table"), -- OK

    init = layers.init, -- if called twice, would break something
    push_layer = layers.push, -- OK
    pop_layer = layers.pop, -- OK

    push_event = events.add, -- OK
    run = run, -- OK
}

return ui
