local text_cache = require("ui.text_cache")
local draw_queue = require("ui.draw_queue")
local label = require("ui.element.label")
local state = require("ui.state")
local utils = require("tests.utils")
local ui = require("ui")
local test = {}

local width, height

function test.layout()
    state.allow_automatic_resizing = true
    label("Hello World!!!")
    width, height = state.width, state.height
    state.allow_automatic_resizing = false
end

function test.teardown()
    utils.remove_graphics_callback()
end

-- checks width, height and that the object matches with one with the same data gotten from text cache
test.sequence = coroutine.create(function()
    local check_text_object = text_cache.get(state.get_font(true), "Hello World!!!", (state.text_wraplimit or math.huge) * ui.scale, state.text_align)
    local text_was_drawn = false

    utils.add_graphics_callback(function(graphics_fun, ...)
        if graphics_fun == "draw" then
            local text_object = ...
            if text_object == check_text_object then
                text_was_drawn = true
            end
        end
    end)


    local check_width, check_height = draw_queue.get_text_size("Hello World!!!", state.get_font(), state.text_wraplimit, state.text_align)
    assert(width == check_width, "label width is wrong")
    assert(height == check_height, "label height is wrong")

    coroutine.yield() -- wait for graphics callback
    assert(text_was_drawn, "did not find correct text object from cache in draw commands")
end)

return test
