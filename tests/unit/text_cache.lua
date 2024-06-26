local text_cache = require("ui.text_cache")
local utils = require("tests.utils")

local log = utils.log.new()
local test = {}

function test.layout()
    log:draw()
end

-- most of the text_cache functionality is already tested, the main thing to check here is the deletion of unused text objects after too many have been cached already
test.sequence = coroutine.create(function()
    local o1 = text_cache.get(love.graphics.getFont(), "Hello", math.huge, "left")
    local o2 = text_cache.get(love.graphics.getFont(), "Hello", math.huge, "left")
    assert(o1 == o2, "same data should give same object")
    -- get 10 unique objects
    for i = 1, 10 do
        text_cache.get(love.graphics.getFont(), "Hello" .. i, math.huge, "left")
    end
    -- make sure that the cache is updated, so the now unused objects from before are not cached
    utils.wait(1)
    o1 = text_cache.get(love.graphics.getFont(), "Hello", math.huge, "left")
    assert(o1 ~= o2, "object should not be the same after cache was updated")
end)

return test
