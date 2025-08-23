local cursor = require("ui.cursor")
local stack_manager = require("ui.stack_manager")
local unittest = require("tests.unittest")

local T = {}

function T.set_up_case()
    -- error("k")
    print("set_up_case")
end

function T.tear_down_case()
    error("k")
    print("tear_down_case")
end

function T.set_up()
    -- error("k")
    print("set_up")
end

function T.tear_down()
    -- error("k")
    print("tear_down")
end

function T.test_cursor_stack()
    unittest.assert(false, "hello")
end

function T.test_cursor_stack_rollback()
    unittest.assert(true)
end

function T.test_ex1()
    error("hello 2")
end

function T.test_ex2() end

function T.test_ex3()
    unittest.assert_error(function()
        error()
    end)
end

return T
