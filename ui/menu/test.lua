local ui = require("ui")
local state = require("ui.state")
local rectangle = require("ui.element.rectangle")
local label = require("ui.element.label")
local icon = require("ui.element.icon")
local background_area = require("ui.area.background")
local area = require("ui.area")
local button = require("ui.element.button")
local theme = require("ui.theme")
local scroll = require("ui.area.scroll")
local collapse = require("ui.area.collapse")
local layers = require("ui.layers")
local test_overlay = require("ui.menu.test_overlay")
local toggle = require("ui.element.toggle")

local infinite_scroll_example = require("ui.menu.infinite_scroll_example")

local button_state = {}
local scroll_state1 = {}
local scroll_state2 = {}
local toggle_state = {}

-- small menu for testing
return function()
    background_area.start()

    -- top left corner with a bit of padding
    state.x = 10
    state.y = 10
    -- dimensions (and all manually controlled state)
    -- is kept as long as not overwritten manually
    -- (apart from some exceptions (see below))
    state.width = 100
    state.height = 50

    -- rectangle in top left corner
    rectangle()
    if state.clicked then
        print("clicked top left rectangle")
        layers.push(test_overlay)
    end

    -- rectangle to the right of the last one with 10 padding
    state.x = state.x + state.width + 10
    rectangle()
    if state.clicked then
        print("clicked 2nd rectangle from top left")
    end

    -- rectangle to the bottom of the first one with 10 padding
    state.x = 10
    state.y = state.y + state.height + 10
    rectangle()

    -- add some padding around the area before drawing
    local bounds = area.get_bounds()
    bounds.left = bounds.left - 4
    bounds.top = bounds.top - 4
    bounds.right = bounds.right + 4
    bounds.bottom = bounds.bottom + 4

    theme.rectangle_color[1] = 1
    background_area.done()
    theme.rectangle_color[1] = 0.2

    -- rectangle in the bottom left corner with adjusted anchor
    state.y = ui.get_height() - 10
    state.anchor.y = 1
    rectangle()
    if state.clicked then
        print("clicked bottom left rectangle")
    end

    -- make scrollable
    scroll.start(scroll_state1, "vertical", 100)

    -- centered rectangle
    state.x = ui.get_width() / 2
    state.y = ui.get_height() / 2
    state.anchor.x = 0.5
    state.anchor.y = 0.5
    rectangle("line") -- just border, not filled
    if state.clicked then
        print("clicked on center rectangle")
    end
    -- put some text inside
    -- (label sets dimensions which makes centering in the rectangle easier)
    label("Hello")

    state.y = state.y + 79
    state.height = 50
    state.text_wraplimit = 200
    button(button_state, "Press me! with wrap!")
    if state.clicked then
        print("I was pressed!")
    end

    -- nested scroll
    scroll.start(scroll_state2, "horizontal", 200)
    state.y = state.y + state.height + 10
    for _ = 1, 5 do
        rectangle()
        state.x = state.x + state.width + 4
    end
    scroll.done()

    state.y = state.y + state.height + 10
    state.height = 90

    scroll.done()


    state.x = ui.get_width() / 3 * 2
    state.y = ui.get_height() / 3
    state.anchor.x = 0
    state.anchor.y = 0
    infinite_scroll_example()

    collapse.start()

    -- rectangle with width of 1/3 screen minus 20 padding (10 on each side)
    state.x = 10
    state.y = ui.get_height() / 2
    state.anchor.x = 0
    state.width = ui.get_width() / 3 - 20
    rectangle()

    -- draw icon in center
    state.x = state.x + state.width / 2
    state.y = state.y + state.height / 2
    state.anchor.x = 0.5
    state.anchor.y = 0.5
    icon("emoji-smile")

    collapse.done((math.sin(love.timer.getTime() * 5) + 1) * 0.5)


    state.x = ui.get_width()
    state.y = ui.get_height() / 2
    state.anchor.x = 1
    state.anchor.y = 0.5
    state.width = 100
    state.height = 50
    toggle(toggle_state)
end
