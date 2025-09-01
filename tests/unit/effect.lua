local monkeypatch = require("tests.monkeypatch")
local unittest = require("tests.unittest")
local effect = require("ui.effect")

local T = {}

local deltatime = 1

function T.set_up_case()
    love.timer.getDelta = monkeypatch.replace(love.timer.getDelta, function()
        return deltatime
    end)
end

function T.tear_down_case()
    love.timer.getDelta = monkeypatch.get_original(love.timer.getDelta)
end

function T.test_follow()
    local value = 0

    for _ = 1, 10 do
        value = effect.follow(value, 9.5, 1)
    end

    unittest.assert(value == 9.5)

    value = 10
    for _ = 1, 10 do
        value = effect.follow(value, 1, 2)
    end
    unittest.assert(value == 1)

    unittest.assert(effect.follow(nil, 1) == 1)
end

return T
