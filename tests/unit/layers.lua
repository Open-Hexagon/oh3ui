local layers = require("ui.layers")
local text_cache = require("ui.text_cache")
local label = require("ui.element.label")
local utils = require("tests.utils")
local state = require("ui.state")
local ui = require("ui")
local test = {}

local allows_interaction = {}

local function layer3()
	state.x = ui.get_width()
	state.anchor.x = 1
	label("Layer 3")
	allows_interaction[4] = layers.allow_interaction
end

local function layer2()
	state.x = ui.get_width()
	state.anchor.x = 1
	label("Layer 2")
	allows_interaction[3] = layers.allow_interaction
end

local function layer1()
	state.x = ui.get_width()
	state.anchor.x = 1
	label("Layer 1")
	allows_interaction[2] = layers.allow_interaction
end

function test.layout()
	label("Layer 0")
	allows_interaction[1] = layers.allow_interaction
end

function test.teardown()
    utils.remove_graphics_callback()
end

test.sequence = coroutine.create(function()
    local check_text_objects = {}
    for i = 0, 3 do
        check_text_objects[i + 1] = text_cache.get(state.get_font(true), "Layer " .. i, (state.text_wraplimit or math.huge) * ui.scale, state.text_align)
    end
    local text_was_drawn = { false, false, false, false }

    utils.add_graphics_callback(function(graphics_fun, ...)
        if graphics_fun == "draw" then
            local text_object = ...
	    for i = 1, 4 do
                if text_object == check_text_objects[i] then
                    text_was_drawn[i] = true
	        end
	    end
        end
    end)

    coroutine.yield()
    assert(text_was_drawn[1], "Layer 0 label should have been drawn")
    assert(not text_was_drawn[2], "Layer 1 label should not have been drawn")
    assert(not text_was_drawn[3], "Layer 2 label should not have been drawn")
    assert(not text_was_drawn[4], "Layer 3 label should not have been drawn")
    assert(allows_interaction[1], "Layer 0 should be interactable")

    -- add next layer
    layers.push(layer1)
    coroutine.yield()
    coroutine.yield()
    assert(text_was_drawn[1], "Layer 0 label should have been drawn")
    assert(text_was_drawn[2], "Layer 1 label should have been drawn")
    assert(not text_was_drawn[3], "Layer 2 label should not have been drawn")
    assert(not text_was_drawn[4], "Layer 3 label should not have been drawn")
    assert(not allows_interaction[1], "Layer 0 should not be interactable")
    assert(allows_interaction[2], "Layer 1 should be interactable")

    -- add next layer
    layers.push(layer2)
    coroutine.yield()
    coroutine.yield()
    assert(text_was_drawn[1], "Layer 0 label should have been drawn")
    assert(text_was_drawn[2], "Layer 1 label should have been drawn")
    assert(text_was_drawn[3], "Layer 2 label should have been drawn")
    assert(not text_was_drawn[4], "Layer 3 label should not have been drawn")
    assert(not allows_interaction[1], "Layer 0 should not be interactable")
    assert(not allows_interaction[2], "Layer 1 should not be interactable")
    assert(allows_interaction[3], "Layer 2 should be interactable")

    -- add next layer
    layers.push(layer3)
    coroutine.yield()
    coroutine.yield()
    assert(text_was_drawn[1], "Layer 0 label should have been drawn")
    assert(text_was_drawn[2], "Layer 1 label should have been drawn")
    assert(text_was_drawn[3], "Layer 2 label should have been drawn")
    assert(text_was_drawn[4], "Layer 3 label should have been drawn")
    assert(not allows_interaction[1], "Layer 0 should not be interactable")
    assert(not allows_interaction[2], "Layer 1 should not be interactable")
    assert(not allows_interaction[3], "Layer 2 should not be interactable")
    assert(allows_interaction[4], "Layer 3 should be interactable")

    -- remove layer
    layers.pop()
    coroutine.yield()
    assert(not allows_interaction[1], "Layer 0 should not be interactable")
    assert(not allows_interaction[2], "Layer 1 should not be interactable")
    assert(allows_interaction[3], "Layer 2 should be interactable")

    -- remove layer
    layers.pop()
    coroutine.yield()
    assert(not allows_interaction[1], "Layer 0 should not be interactable")
    assert(allows_interaction[2], "Layer 1 should be interactable")

    -- remove layer
    layers.pop()
    coroutine.yield()
    assert(allows_interaction[1], "Layer 0 should be interactable")
end)

return test
