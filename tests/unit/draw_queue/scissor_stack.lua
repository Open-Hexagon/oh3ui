local unittest = require("tests.unittest")
local monkeypatch = require("tests.monkeypatch")
local ss = require("ui.draw_queue.scissor_stack")
local volatile_data = require("ui.shared_data").volatile

local T = {}

function T.test_all()
    ss.push(0, 0, 100, 100)

    unittest.assert(volatile_data.mask_index == 1)
    unittest.assert_equal_lists({ love.graphics.getScissor() }, volatile_data.mask_stack[1])

    ss.push(50, 50, 100, 100)

    unittest.assert(volatile_data.mask_index == 2)
    unittest.assert_equal_lists({ love.graphics.getScissor() }, volatile_data.mask_stack[2])

    ss.pop()

    unittest.assert(volatile_data.mask_index == 1)
    unittest.assert_equal_lists({ love.graphics.getScissor() }, volatile_data.mask_stack[1])

    ss.pop()
    unittest.assert(volatile_data.mask_index == 0)
    local a = love.graphics.getScissor()
    unittest.assert(type(a) == "nil")

    ss.push(50, 50, 100, 100)

    unittest.assert(volatile_data.mask_index == 1)
    unittest.assert_equal_lists({ love.graphics.getScissor() }, volatile_data.mask_stack[1])
    ss.pop()
end

return T
