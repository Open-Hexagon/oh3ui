local cursor = require("ui.cursor")
local stack_manager = require("ui.stack_manager")
local unittest = require("tests.unittest")

local T = {}

local l, t, r, b

function T.set_up()
    stack_manager.push_record()

    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 10, 10
    cursor.anchor_x, cursor.anchor_y = 0, 0
    cursor.auto_reshape = false

    cursor.area_expansion_on()
end

function T.tear_down()
    stack_manager.pop_record()
end

function T.test_area()
    cursor.start_area()

    cursor.x = 0
    cursor.y = 0
    cursor.place()

    cursor.start_area()

    cursor.x = 100
    cursor.y = 100
    cursor.place()

    cursor.x = 200
    cursor.y = 200
    cursor.place()

    -- inner areas will update outer areas when finish_area is called
    cursor.finish_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 100)
    unittest.assert(t == 100)
    unittest.assert(r == 210)
    unittest.assert(b == 210)

    cursor.finish_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 0)
    unittest.assert(t == 0)
    unittest.assert(r == 210)
    unittest.assert(b == 210)
end

function T.test_empty_area()
    cursor.start_area()

    cursor.x = 0
    cursor.y = 0
    cursor.place()

    cursor.x = 100
    cursor.y = 100
    cursor.place()

    -- areas that start and immediately end should not affect areas below
    cursor.start_area()
    cursor.x = 200
    cursor.y = 200
    cursor.finish_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 200)
    unittest.assert(t == 200)
    unittest.assert(r == 210)
    unittest.assert(b == 210)

    cursor.finish_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 0)
    unittest.assert(t == 0)
    unittest.assert(r == 110)
    unittest.assert(b == 110)
end

function T.test_area_rollback()
    cursor.start_area()

    cursor.x = 0
    cursor.y = 0
    cursor.place()

    cursor.x = 100
    cursor.y = 100
    cursor.place()

    stack_manager.push_record()
    unittest.assert_error(function()
        cursor.finish_area()
    end, "we should be at the bottom of the stack")

    cursor.start_area()

    cursor.x = 200
    cursor.y = 200
    cursor.place()

    -- an area that is prematurely terminated by a record pop will not update any outer areas
    stack_manager.pop_record()

    -- cursor remains unaffected
    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 200)
    unittest.assert(t == 200)
    unittest.assert(r == 210)
    unittest.assert(b == 210)

    cursor.finish_area()

    -- this area doesn't know about the square at (200, 200)
    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 0)
    unittest.assert(t == 0)
    unittest.assert(r == 110)
    unittest.assert(b == 110)
end

function T.test_area_underflow()
    unittest.assert_error(function()
        cursor.finish_area()
    end, "we should be at the bottom of the stack")
end

function T.test_put_area()
    cursor.start_area()

    cursor.x = 0
    cursor.y = 0
    cursor.place()

    cursor.x = 100
    cursor.y = 100
    cursor.place()

    cursor.put_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 0)
    unittest.assert(t == 0)
    unittest.assert(r == 110)
    unittest.assert(b == 110)

    cursor.finish_area()
end

function T.test_put_empty_area()
    cursor.start_area()

    cursor.put_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 0)
    unittest.assert(t == 0)
    unittest.assert(r == 10)
    unittest.assert(b == 10)

    cursor.finish_area()
end

function T.test_area_expansion_toggle()
    cursor.start_area()

    cursor.x = 0
    cursor.y = 0
    cursor.place()

    cursor.x = 100
    cursor.y = 100
    cursor.area_expansion_off()
    cursor.place()
    cursor.area_expansion_on()

    cursor.put_area()

    l, t, r, b = cursor.ltrb()
    unittest.assert(l == 0)
    unittest.assert(t == 0)
    unittest.assert(r == 10)
    unittest.assert(b == 10)

    cursor.finish_area()
end

return T
