local unittest = require("tests.unittest")
local draw_queue = require("ui.draw_queue")
local monkeypatch = require("tests.monkeypatch")
local cursor = require("ui.cursor")
local placement = cursor.projected_placement
local volatile_data = require("ui.shared_data").volatile
local stack_manager = require("ui.stack_manager")

local T = {}

local l, t, r, b
local dq_pop_called

function T.set_up_case()
    unittest.skip("needs redo after major changes")
    -- disable the push function, intercept its arguments
    draw_queue.push_scissor = monkeypatch.replace(draw_queue.push_scissor, function(l2, t2, r2, b2)
        l, t, r, b = l2, t2, r2, b2
    end)

    -- disable the pop function, add flag to probe calls
    draw_queue.pop_scissor = monkeypatch.replace(draw_queue.pop_scissor, function()
        dq_pop_called = dq_pop_called + 1
    end)
end

function T.tear_down_case()
    draw_queue.push_scissor = monkeypatch.get_original(draw_queue.push_scissor)
    draw_queue.pop_scissor = monkeypatch.get_original(draw_queue.pop_scissor)
end

function T.tear_down()
    volatile_data.mask_index = 0
end

function T.test_mask()
    cursor.reset(100, 100)

    mask.push()

    unittest.assert(placement.left == l)
    unittest.assert(placement.top == t)
    unittest.assert(placement.right == r)
    unittest.assert(placement.bottom == b)

    unittest.assert(volatile_data.mask_index == 1)

    dq_pop_called = 0
    mask.pop()
    unittest.assert(dq_pop_called == 1)
    unittest.assert(volatile_data.mask_index == 0)
end

function T.test_mask_underflow()
    volatile_data.mask_index = 10
    stack_manager.push_record()
    unittest.assert_error(mask.pop)
    stack_manager.pop_record()
end

return T
