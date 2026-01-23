local unittest = require("tests.unittest")
local events = require("ui.events")

local T = {}

function T.test_events()
    -- clear and add events
    local test_events = {
        { "mousepressed", 1, 1 },
        { "mousereleased", 1, 1 },
        { "wheelmoved", 0, -1 },
    }

    events.clear()
    events.add("a", 1, 2, 3, 4, 5)
    events.add("b", 1)
    events.add("c", 1)
    events.add("d", 1)

    -- repeat to test overwriting events
    events.clear()
    for i = 1, #test_events do
        events.add(unpack(test_events[i]))
    end

    -- iterate over them
    local index = 0
    for event in events.iterate() do
        index = index + 1
        for i = 1, #event do
            unittest.assert(test_events[index][i] == event[i], "Events don't match")
        end
    end

    -- iterate over them with filter
    index = 0
    for event in events.iterate("mouse.*") do
        index = index + 1
        for i = 1, #event do
            unittest.assert(test_events[index][i] == event[i], "Events don't match")
        end
    end

    index = 1
    for event in
        events.iterate(function(str)
            return str == "mousereleased" or str == "wheelmoved"
        end)
    do
        index = index + 1
        for i = 1, #event do
            unittest.assert(test_events[index][i] == event[i], "Events don't match")
        end
    end
end

return T
