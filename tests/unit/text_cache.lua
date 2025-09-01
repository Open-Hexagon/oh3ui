local monkeypatch = require("tests.monkeypatch")
local text_cache = require("ui.text.cache")
local unittest = require("tests.unittest")

local T = {}

local time = 0

function T.set_up_case()
    love.timer.getTime = monkeypatch.replace(love.timer.getTime, function()
        return time
    end)
end

function T.tear_down_case()
    love.timer.getTime = monkeypatch.get_original(love.timer.getTime)
end

function T.test_text_cache()
    local _
    local o1 = text_cache.get(love.graphics.getFont(), "Hello", math.huge, "left")
    local o2 = text_cache.get(love.graphics.getFont(), "Hello", math.huge, "left")
    unittest.assert(o1 == o2, "same data should give same object")
    -- get 10 unique objects
    for i = 1, 10 do
        _ = text_cache.get(love.graphics.getFont(), "Hello" .. i, math.huge, "left")
    end

    -- advance time by 1
    time = 1
    -- this should set the usage of earlier text objects to 0
    _ = text_cache.get(love.graphics.getFont(), "A", math.huge, "left")
    -- advance time by 1
    time = 2
    -- this should clear the cache of earlier text objects to 0
    _ = text_cache.get(love.graphics.getFont(), "A", math.huge, "left")

    o1 = text_cache.get(love.graphics.getFont(), "Hello", math.huge, "left")
    unittest.assert(o1 ~= o2, "object should not be the same after cache was updated")
end

return T
