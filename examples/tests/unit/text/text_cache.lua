local text_cache_get = require("ui.text.cache")
local unittest = require("tests.unittest")
local memoize = require("extlibs.memoize")

local T = {}

function T.test_text_cache()
    local _
    local o1 = text_cache_get(love.graphics.getFont(), "Hello", math.huge, "left")
    local o2 = text_cache_get(love.graphics.getFont(), "Hello", math.huge, "left")
    unittest.assert(o1 == o2, "same data should give same object")
    -- get 10 unique objects
    for i = 1, 10 do
        _ = text_cache_get(love.graphics.getFont(), "Hello" .. i, math.huge, "left")
    end

    local o3 = text_cache_get(love.graphics.getFont(), "Hello1", math.huge, "left")

    -- this should set usage to 0
    memoize.master_sweep()

    local o4 = text_cache_get(love.graphics.getFont(), "Hello1", math.huge, "left")
    unittest.assert(o3 == o4, "setting usage to 0 should not clear object")

    -- this should clear objects with 0 usage
    memoize.master_sweep()

    o1 = text_cache_get(love.graphics.getFont(), "Hello", math.huge, "left")
    unittest.assert(o1 ~= o2, "object should not be the same after cache was updated")
end

return T
