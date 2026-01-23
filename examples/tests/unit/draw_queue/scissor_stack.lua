local unittest = require("tests.unittest")
local ss = require("ui.draw_queue.scissor_stack")

local T = {}

local x, y, w, h

function T.test_intersect()
    ss.push(0, 0, 100, 100)
    x, y, w, h = love.graphics.getScissor()
    unittest.assert(x == 0)
    unittest.assert(y == 0)
    unittest.assert(w == 100)
    unittest.assert(h == 100)

    ss.push(50, 50, 150, 150)
    x, y, w, h = love.graphics.getScissor()
    unittest.assert(x == 50)
    unittest.assert(y == 50)
    unittest.assert(w == 50)
    unittest.assert(h == 50)

    ss.pop()
    x, y, w, h = love.graphics.getScissor()
    unittest.assert(x == 0)
    unittest.assert(y == 0)
    unittest.assert(w == 100)
    unittest.assert(h == 100)

    ss.pop()
    x, y, w, h = love.graphics.getScissor()
    unittest.assert(type(x) == "nil")

    ss.push(50, 50, 100, 100)
    x, y, w, h = love.graphics.getScissor()
    unittest.assert(x == 50)
    unittest.assert(y == 50)
    unittest.assert(w == 50)
    unittest.assert(h == 50)

    ss.pop()

    unittest.assert_error(ss.pop, "should be at bottom of scissor stack")
end

function T.test_rounding()
    ss.push(0.5, 0.3, 99.3, 99.1)
    x, y, w, h = love.graphics.getScissor()
    unittest.assert(x == 0)
    unittest.assert(y == 0)
    unittest.assert(w == 100)
    unittest.assert(h == 100)
    ss.pop()
end

return T
