local utils = require("tests.utils")
local events = require("ui.events")
local state = require("ui.state")
local test = {}

local log = utils.log.new()

function test.layout()
    state.allow_automatic_resizing = true
    log:draw()
    state.allow_automatic_resizing = false
end

test.sequence = coroutine.create(function()
    -- clear and add events
    local test_events = {
        { "mousepressed", 1, 1 },
        { "mousereleased", 1, 1 },
        { "wheelmoved", 0, -1 },
    }
    log:add("clearing events")
    events.clear()
    for i = 1, #test_events do
        log:add("adding event: " .. test_events[i][1])
        events.add(unpack(test_events[i]))
    end

    -- iterate over them
    local index = 0
    for event in events.iterate() do
        index = index + 1
        for i = 1, #event do
            assert(test_events[index][i] == event[i], "Events don't match")
        end
    end

    -- iterate over them with filter
    index = 0
    for event in events.iterate("mouse.*") do
        index = index + 1
        for i = 1, #event do
            assert(test_events[index][i] == event[i], "Events don't match")
        end
    end
end)

return test
