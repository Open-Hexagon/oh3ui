local cursor = require("ui.cursor")
local placement = cursor.projected_placement
local stack_manager = require("ui.stack_manager")
local unittest = require("tests.unittest")

local T = {}

function T.set_up()
    stack_manager.push_record()

    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 10, 10
    cursor.anchor_x, cursor.anchor_y = 0, 0
    cursor.auto_reshape = false

    placement.left = 0
    placement.top = 0
    placement.right = 0
    placement.bottom = 0
    placement.x = 0
    placement.y = 0
end

function T.tear_down()
    stack_manager.pop_record()
end

function T.test_stack_underflow()
    unittest.assert_error(cursor.pop_translation, "we should be at the bottom of the stack")
end

function T.test_translate()
    cursor.push_translation(100, 0)

    cursor.place()
    unittest.assert(placement.left == 100)
    unittest.assert(placement.top == 0)
    unittest.assert(placement.right == 110)
    unittest.assert(placement.bottom == 10)
    unittest.assert(placement.x == 100)
    unittest.assert(placement.y == 0)

    cursor.push_translation(0, 100)

    cursor.place()
    unittest.assert(placement.left == 100)
    unittest.assert(placement.top == 100)
    unittest.assert(placement.right == 110)
    unittest.assert(placement.bottom == 110)
    unittest.assert(placement.x == 100)
    unittest.assert(placement.y == 100)

    cursor.pop_translation()
    cursor.pop_translation()

    cursor.place()
    unittest.assert(placement.left == 0)
    unittest.assert(placement.top == 0)
    unittest.assert(placement.right == 10)
    unittest.assert(placement.bottom == 10)
    unittest.assert(placement.x == 0)
    unittest.assert(placement.y == 0)
end

function T.test_translate_rollback()
    cursor.push_translation(100, 0)

    cursor.place()
    unittest.assert(placement.left == 100)
    unittest.assert(placement.top == 0)
    unittest.assert(placement.right == 110)
    unittest.assert(placement.bottom == 10)
    unittest.assert(placement.x == 100)
    unittest.assert(placement.y == 0)

    stack_manager.push_record()

    unittest.assert_error(cursor.pop_translation, "we should be at the bottom of the stack")

    cursor.push_translation(0, 50)
    cursor.push_translation(0, 50)

    cursor.place()
    unittest.assert(placement.left == 100)
    unittest.assert(placement.top == 100)
    unittest.assert(placement.right == 110)
    unittest.assert(placement.bottom == 110)
    unittest.assert(placement.x == 100)
    unittest.assert(placement.y == 100)

    stack_manager.pop_record()

    cursor.pop_translation()

    cursor.place()
    unittest.assert(placement.left == 0)
    unittest.assert(placement.top == 0)
    unittest.assert(placement.right == 10)
    unittest.assert(placement.bottom == 10)
    unittest.assert(placement.x == 0)
    unittest.assert(placement.y == 0)
end

return T
