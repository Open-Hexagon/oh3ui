local cursor = require("ui.cursor")
local projected_placement = cursor.projected_placement
local stack_manager = require("ui.stack_manager")
local unittest = require("tests.unittest")
local draw_data = require("ui.draw_queue.draw_data")

local T = {}

function T.set_up()
    stack_manager.push_record()

    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 10, 10
    cursor.anchor_x, cursor.anchor_y = 0, 0
    cursor.auto_reshape = false

    projected_placement.left = 0
    projected_placement.top = 0
    projected_placement.right = 0
    projected_placement.bottom = 0
    projected_placement.x = 0
    projected_placement.y = 0
end

function T.tear_down()
    stack_manager.pop_record()
    draw_data.clear()
end

function T.test_stack_underflow()
    unittest.assert_error(cursor.pop_translation, "we should be at the bottom of the stack")
end

function T.test_translate()
    unittest.assert_equal_lists({ draw_data.get_translation(cursor.push_translation(100, 0)) }, { 100, 0 })

    cursor.place()
    unittest.assert(projected_placement.left == 100)
    unittest.assert(projected_placement.top == 0)
    unittest.assert(projected_placement.right == 110)
    unittest.assert(projected_placement.bottom == 10)
    unittest.assert(projected_placement.x == 100)
    unittest.assert(projected_placement.y == 0)

    unittest.assert_equal_lists({ draw_data.get_translation(cursor.push_translation(0, 100)) }, { 0, 100 })

    cursor.place()
    unittest.assert(projected_placement.left == 100)
    unittest.assert(projected_placement.top == 100)
    unittest.assert(projected_placement.right == 110)
    unittest.assert(projected_placement.bottom == 110)
    unittest.assert(projected_placement.x == 100)
    unittest.assert(projected_placement.y == 100)

    cursor.pop_translation()
    cursor.pop_translation()

    cursor.place()
    unittest.assert(projected_placement.left == 0)
    unittest.assert(projected_placement.top == 0)
    unittest.assert(projected_placement.right == 10)
    unittest.assert(projected_placement.bottom == 10)
    unittest.assert(projected_placement.x == 0)
    unittest.assert(projected_placement.y == 0)
end

function T.test_translate_rollback()
    unittest.assert_equal_lists({ draw_data.get_translation(cursor.push_translation(100, 0)) }, { 100, 0 })

    cursor.place()
    unittest.assert(projected_placement.left == 100)
    unittest.assert(projected_placement.top == 0)
    unittest.assert(projected_placement.right == 110)
    unittest.assert(projected_placement.bottom == 10)
    unittest.assert(projected_placement.x == 100)
    unittest.assert(projected_placement.y == 0)

    stack_manager.push_record()

    unittest.assert_error(cursor.pop_translation, "we should be at the bottom of the stack")

    unittest.assert_equal_lists({ draw_data.get_translation(cursor.push_translation(0, 50)) }, { 0, 50 })
    unittest.assert_equal_lists({ draw_data.get_translation(cursor.push_translation(0, 50)) }, { 0, 50 })

    cursor.place()
    unittest.assert(projected_placement.left == 100)
    unittest.assert(projected_placement.top == 100)
    unittest.assert(projected_placement.right == 110)
    unittest.assert(projected_placement.bottom == 110)
    unittest.assert(projected_placement.x == 100)
    unittest.assert(projected_placement.y == 100)

    stack_manager.pop_record()

    cursor.pop_translation()

    cursor.place()
    unittest.assert(projected_placement.left == 0)
    unittest.assert(projected_placement.top == 0)
    unittest.assert(projected_placement.right == 10)
    unittest.assert(projected_placement.bottom == 10)
    unittest.assert(projected_placement.x == 0)
    unittest.assert(projected_placement.y == 0)
end

return T
