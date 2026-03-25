local cursor = require("ui.cursor")
local placement = cursor.projected_placement
local stack_manager = require("ui.stack_manager")
local unittest = require("tests.unittest")

local T = {}

local screen_width, screen_height

function T.set_up_case()
    screen_width, screen_height = love.graphics.getDimensions()
end

function T.set_up()
    stack_manager.push_record()

    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 128, 128
    cursor.anchor_x, cursor.anchor_y = 0, 0
    cursor.auto_reshape = "no"

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

function T.test_cursor_reset()
    cursor.reset()
    local width, height = love.graphics.inverseTransformPoint(love.graphics.getDimensions())

    unittest.assert(cursor.x == 0)
    unittest.assert(cursor.y == 0)
    unittest.assert(cursor.width == width)
    unittest.assert(cursor.height == height)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
    unittest.assert(cursor.auto_reshape == "both")

    cursor.width = 10
    cursor.height = 10
    cursor.reset()

    unittest.assert(cursor.x == 0)
    unittest.assert(cursor.y == 0)
    unittest.assert(cursor.width == width)
    unittest.assert(cursor.height == height)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
    unittest.assert(cursor.auto_reshape == "both")
end

function T.test_cursor_stack_push_pop()
    cursor.x, cursor.y = 30, 70
    cursor.width, cursor.height = 50, 80
    cursor.anchor_x, cursor.anchor_y = 0.5, 0.5
    cursor.auto_reshape = "no"

    cursor.push()
    do
        cursor.x, cursor.y = 90, 325
        cursor.width, cursor.height = 410, 35
        cursor.anchor_x, cursor.anchor_y = 1, 1
        cursor.auto_reshape = "both"

        cursor.push()
        do
            cursor.x, cursor.y = 50, 10
            cursor.width, cursor.height = 640, 20
            cursor.anchor_x, cursor.anchor_y = 1, 0
            cursor.auto_reshape = "no"
        end
        cursor.pop()

        unittest.assert(cursor.x == 90)
        unittest.assert(cursor.y == 325)
        unittest.assert(cursor.width == 410)
        unittest.assert(cursor.height == 35)
        unittest.assert(cursor.anchor_x == 1)
        unittest.assert(cursor.anchor_y == 1)
        unittest.assert(cursor.auto_reshape == "both")
    end
    cursor.pop()

    unittest.assert(cursor.x == 30)
    unittest.assert(cursor.y == 70)
    unittest.assert(cursor.width == 50)
    unittest.assert(cursor.height == 80)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)
    unittest.assert(cursor.auto_reshape == "no")
end

function T.test_cursor_stack_underflow()
    unittest.assert_error(cursor.pop)
end

function T.test_cursor_stack_rollback()
    cursor.x, cursor.y = 30, 70
    cursor.width, cursor.height = 50, 80
    cursor.anchor_x, cursor.anchor_y = 0.5, 0.5
    cursor.auto_reshape = "no"

    cursor.push()
    do
        stack_manager.push_record()
        unittest.assert_error(cursor.pop)

        cursor.x, cursor.y = 90, 325
        cursor.width, cursor.height = 410, 35
        cursor.anchor_x, cursor.anchor_y = 1, 1
        cursor.auto_reshape = "both"

        cursor.push()

        cursor.x, cursor.y = 50, 10
        cursor.width, cursor.height = 640, 20
        cursor.anchor_x, cursor.anchor_y = 1, 0
        cursor.auto_reshape = "no"

        stack_manager.pop_record()

        -- rolling back doesn't update the cursor
        unittest.assert(cursor.x == 50)
        unittest.assert(cursor.y == 10)
        unittest.assert(cursor.width == 640)
        unittest.assert(cursor.height == 20)
        unittest.assert(cursor.anchor_x == 1)
        unittest.assert(cursor.anchor_y == 0)
        unittest.assert(cursor.auto_reshape == "no")
    end
    cursor.pop()

    unittest.assert(cursor.x == 30)
    unittest.assert(cursor.y == 70)
    unittest.assert(cursor.width == 50)
    unittest.assert(cursor.height == 80)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)
    unittest.assert(cursor.auto_reshape == "no")
end

function T.test_cursor_stack_peek()
    unittest.assert_error(cursor.peek, "peeking an empty stack should cause error")

    cursor.x, cursor.y = 30, 70
    cursor.width, cursor.height = 50, 80
    cursor.anchor_x, cursor.anchor_y = 0.5, 0.5
    cursor.auto_reshape = "no"

    cursor.push()

    cursor.x, cursor.y = 50, 10
    cursor.width, cursor.height = 640, 20
    cursor.anchor_x, cursor.anchor_y = 1, 0
    cursor.auto_reshape = "no"

    cursor.peek()

    unittest.assert(cursor.x == 30)
    unittest.assert(cursor.y == 70)
    unittest.assert(cursor.width == 50)
    unittest.assert(cursor.height == 80)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)
    unittest.assert(cursor.auto_reshape == "no")

    cursor.x, cursor.y = 50, 10
    cursor.width, cursor.height = 640, 20
    cursor.anchor_x, cursor.anchor_y = 1, 0
    cursor.auto_reshape = "no"

    cursor.pop()

    unittest.assert(cursor.x == 30)
    unittest.assert(cursor.y == 70)
    unittest.assert(cursor.width == 50)
    unittest.assert(cursor.height == 80)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)
    unittest.assert(cursor.auto_reshape == "no")

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_cursor_stack_drop()
    unittest.assert_error(cursor.drop, "dropping an empty stack should cause error")

    cursor.x, cursor.y = 30, 70
    cursor.width, cursor.height = 50, 80
    cursor.anchor_x, cursor.anchor_y = 0.5, 0.5
    cursor.auto_reshape = "no"

    cursor.push()

    cursor.x, cursor.y = 50, 10
    cursor.width, cursor.height = 640, 20
    cursor.anchor_x, cursor.anchor_y = 1, 0
    cursor.auto_reshape = "no"

    cursor.drop()

    unittest.assert(cursor.x == 50)
    unittest.assert(cursor.y == 10)
    unittest.assert(cursor.width == 640)
    unittest.assert(cursor.height == 20)
    unittest.assert(cursor.anchor_x == 1)
    unittest.assert(cursor.anchor_y == 0)
    unittest.assert(cursor.auto_reshape == "no")

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_get_edges()
    local a, b, c, d = cursor.get_edges()

    unittest.assert(a == cursor.x - cursor.anchor_x * cursor.width)
    unittest.assert(b == cursor.y - cursor.anchor_y * cursor.height)
    unittest.assert(c == cursor.x + (1 - cursor.anchor_x) * cursor.width)
    unittest.assert(d == cursor.y + (1 - cursor.anchor_y) * cursor.height)
end

function T.test_do_auto_reshape()
    do
        cursor.x, cursor.y = 30, 70
        cursor.width, cursor.height = 50, 80
        cursor.anchor_x, cursor.anchor_y = 0.5, 0.5
        cursor.auto_reshape = "both" -- ! do_auto_reshape cares about this value

        cursor.push()

        cursor.x, cursor.y = 50, 10
        cursor.width, cursor.height = 640, 20
        cursor.anchor_x, cursor.anchor_y = 1, 0
        cursor.auto_reshape = "no" -- ! not this one

        cursor.do_auto_reshape()

        unittest.assert(cursor.x == 30)
        unittest.assert(cursor.y == 70)
        unittest.assert(cursor.width == 640)
        unittest.assert(cursor.height == 20)
        unittest.assert(cursor.anchor_x == 0.5)
        unittest.assert(cursor.anchor_y == 0.5)
        unittest.assert(cursor.auto_reshape == "both")

        unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
    end

    do
        cursor.x, cursor.y = 30, 70
        cursor.width, cursor.height = 50, 80
        cursor.anchor_x, cursor.anchor_y = 0.5, 0.5
        cursor.auto_reshape = "no" -- ! do_auto_reshape cares about this value

        cursor.push()

        cursor.x, cursor.y = 50, 10
        cursor.width, cursor.height = 640, 20
        cursor.anchor_x, cursor.anchor_y = 1, 0
        cursor.auto_reshape = "both" -- ! not this one

        cursor.do_auto_reshape()

        unittest.assert(cursor.x == 30)
        unittest.assert(cursor.y == 70)
        unittest.assert(cursor.width == 50)
        unittest.assert(cursor.height == 80)
        unittest.assert(cursor.anchor_x == 0.5)
        unittest.assert(cursor.anchor_y == 0.5)
        unittest.assert(cursor.auto_reshape == "no")

        unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
    end
end

function T.test_h_array()
    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 10, 10

    local n = 10
    cursor.h_array(n, 10)
    for i = 1, n do
        cursor.pop()

        unittest.assert(cursor.x == (i - 1) * 20)
        unittest.assert(cursor.y == 0)
        unittest.assert(cursor.width == 10)
        unittest.assert(cursor.height == 10)
    end

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_v_array()
    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 10, 10

    local n = 10
    cursor.v_array(n, 10)
    for i = 1, n do
        cursor.pop()

        unittest.assert(cursor.x == 0)
        unittest.assert(cursor.y == (i - 1) * 20)
        unittest.assert(cursor.width == 10)
        unittest.assert(cursor.height == 10)
    end

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_h_split()
    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 70, 70

    local n = 4
    local a, b = cursor.h_subdivide(n, 10)
    unittest.assert(a == n)
    unittest.assert(b == 10)
    for i = 1, n do
        cursor.pop()

        unittest.assert(cursor.x == (i - 1) * 20)
        unittest.assert(cursor.y == 0)
        unittest.assert(cursor.width == 10)
        unittest.assert(cursor.height == 70)
    end

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_v_split()
    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 70, 70

    local n = 4
    local a, b = cursor.v_subdivide(n, 10)
    unittest.assert(a == n)
    unittest.assert(b == 10)
    for i = 1, n do
        cursor.pop()

        unittest.assert(cursor.x == 0)
        unittest.assert(cursor.y == (i - 1) * 20)
        unittest.assert(cursor.width == 70)
        unittest.assert(cursor.height == 10)
    end

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_combine()
    cursor.anchor_x = 0.5
    cursor.anchor_y = 0.5

    cursor.x, cursor.y = 5, 5
    cursor.width, cursor.height = 10, 10

    cursor.push()

    cursor.x, cursor.y = 15, 15
    cursor.width, cursor.height = 10, 10

    cursor.combine()

    unittest.assert(cursor.x == 10)
    unittest.assert(cursor.y == 10)
    unittest.assert(cursor.width == 20)
    unittest.assert(cursor.height == 20)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_peek_combine()
    cursor.anchor_x = 0.5
    cursor.anchor_y = 0.5

    cursor.x, cursor.y = 5, 5
    cursor.width, cursor.height = 10, 10

    cursor.push()

    cursor.x, cursor.y = 15, 15
    cursor.width, cursor.height = 10, 10

    cursor.combine(true)

    unittest.assert(cursor.x == 10)
    unittest.assert(cursor.y == 10)
    unittest.assert(cursor.width == 20)
    unittest.assert(cursor.height == 20)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)

    cursor.pop()

    unittest.assert(cursor.x == 5)
    unittest.assert(cursor.y == 5)
    unittest.assert(cursor.width == 10)
    unittest.assert(cursor.height == 10)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.5)

    unittest.assert_error(cursor.pop, "we should be at the bottom of the stack")
end

function T.test_combine_underflow()
    unittest.assert_error(cursor.combine)
end

function T.test_change_anchor()
    local l, t, r, b, l2, t2, r2, b2

    cursor.x, cursor.y = 0, 0
    cursor.width, cursor.height = 10, 10

    l, t, r, b = cursor.get_edges()

    cursor.change_anchor(1)

    l2, t2, r2, b2 = cursor.get_edges()

    unittest.assert(l == l2)
    unittest.assert(t == t2)
    unittest.assert(r == r2)
    unittest.assert(b == b2)
    unittest.assert(cursor.anchor_x == 1)
    unittest.assert(cursor.anchor_y == 1)

    cursor.change_anchor(0.5, 0.7)

    l2, t2, r2, b2 = cursor.get_edges()

    unittest.assert(l == l2)
    unittest.assert(t == t2)
    unittest.assert(r == r2)
    unittest.assert(b == b2)
    unittest.assert(cursor.anchor_x == 0.5)
    unittest.assert(cursor.anchor_y == 0.7)
end

function T.test_inset_outset()
    local l, t, r, b, l2, t2, r2, b2
    l, t, r, b = cursor.get_edges()

    cursor.inset(10)

    l2, t2, r2, b2 = cursor.get_edges()
    unittest.assert(l + 10 == l2)
    unittest.assert(t + 10 == t2)
    unittest.assert(r - 10 == r2)
    unittest.assert(b - 10 == b2)

    cursor.outset(10)

    l2, t2, r2, b2 = cursor.get_edges()
    unittest.assert(l == l2)
    unittest.assert(t == t2)
    unittest.assert(r == r2)
    unittest.assert(b == b2)
end

function T.test_h_linspace()
    cursor.width = 10
    for x, i in cursor.h_linspace(11) do
        unittest.assert(x + 1 == i)
    end
end

function T.test_v_linspace()
    cursor.height = 10
    for y, i in cursor.v_linspace(11) do
        unittest.assert(y + 1 == i)
    end
end

function T.test_shift_udlr()
    cursor.x = 0
    cursor.y = 0
    cursor.width = 10
    cursor.height = 10

    cursor.shift_left()
    cursor.shift_left(10, 2)

    cursor.shift_down()
    cursor.shift_down(20, 2)

    cursor.shift_right()
    cursor.shift_right(10, 2)

    cursor.shift_up()
    cursor.shift_up(20, 2)

    unittest.assert(cursor.x == 0)
    unittest.assert(cursor.y == 0)
    unittest.assert(cursor.width == 10)
    unittest.assert(cursor.height == 10)
end

function T.test_is_degenerate()
    cursor.width = -1
    unittest.assert(cursor.is_degenerate())

    cursor.width = 0
    cursor.height = -1
    unittest.assert(cursor.is_degenerate())
end

function T.test_place()
    cursor.width = 100
    cursor.height = 100

    do
        cursor.x = 0
        cursor.y = 0
        cursor.anchor_x = 0
        cursor.anchor_y = 0

        cursor.place()

        unittest.assert(placement.left == 0)
        unittest.assert(placement.top == 0)
        unittest.assert(placement.right == 100)
        unittest.assert(placement.bottom == 100)
        unittest.assert(placement.x == 0)
        unittest.assert(placement.y == 0)
    end
    do
        cursor.x = 100
        cursor.y = 50
        cursor.anchor_x = 1
        cursor.anchor_y = 0.5

        cursor.place()

        unittest.assert(placement.left == 0)
        unittest.assert(placement.top == 0)
        unittest.assert(placement.right == 100)
        unittest.assert(placement.bottom == 100)
        unittest.assert(placement.x == 100)
        unittest.assert(placement.y == 50)
    end

    do
        cursor.x = 0
        cursor.y = 0
        cursor.anchor_x = 0
        cursor.anchor_y = 0

        cursor.place(50, 50)

        unittest.assert(placement.left == 0)
        unittest.assert(placement.top == 0)
        unittest.assert(placement.right == 50)
        unittest.assert(placement.bottom == 50)
        unittest.assert(placement.x == 0)
        unittest.assert(placement.y == 0)
    end
    do
        cursor.x = 50
        cursor.y = 50
        cursor.anchor_x = 0.5
        cursor.anchor_y = 0.5

        cursor.place(50, 50)

        unittest.assert(placement.left == 25)
        unittest.assert(placement.top == 25)
        unittest.assert(placement.right == 75)
        unittest.assert(placement.bottom == 75)
        unittest.assert(placement.x == 50)
        unittest.assert(placement.y == 50)
    end
end

function T.test_v_squeeze()
    cursor.width, cursor.height = 100, 100
    cursor.v_squeeze(10)
    unittest.assert(cursor.x == 0)
    unittest.assert(cursor.y == 10)
    unittest.assert(cursor.width == 100)
    unittest.assert(cursor.height == 80)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
end

function T.test_h_squeeze()
    cursor.width, cursor.height = 100, 100
    cursor.h_squeeze(10)
    unittest.assert(cursor.x == 10)
    unittest.assert(cursor.y == 0)
    unittest.assert(cursor.width == 80)
    unittest.assert(cursor.height == 100)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
end

function T.test_v_stretch()
    cursor.width, cursor.height = 100, 100
    cursor.v_stretch(10)
    unittest.assert(cursor.x == 0)
    unittest.assert(cursor.y == -10)
    unittest.assert(cursor.width == 100)
    unittest.assert(cursor.height == 120)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
end

function T.test_h_stretch()
    cursor.width, cursor.height = 100, 100
    cursor.h_stretch(10)
    unittest.assert(cursor.x == -10)
    unittest.assert(cursor.y == 0)
    unittest.assert(cursor.width == 120)
    unittest.assert(cursor.height == 100)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
end

function T.test_clip_left()
    cursor.width, cursor.height = 100, 100
    cursor.clip_left(10)
    unittest.assert(cursor.x == 10)
    unittest.assert(cursor.y == 0)
    unittest.assert(cursor.width == 90)
    unittest.assert(cursor.height == 100)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
end

function T.test_clip_top()
    cursor.width, cursor.height = 100, 100
    cursor.clip_top(10)
    unittest.assert(cursor.x == 0)
    unittest.assert(cursor.y == 10)
    unittest.assert(cursor.width == 100)
    unittest.assert(cursor.height == 90)
    unittest.assert(cursor.anchor_x == 0)
    unittest.assert(cursor.anchor_y == 0)
end

function T.test_clip_right()
    cursor.x, cursor.y = 100, 100
    cursor.width, cursor.height = 100, 100
    cursor.anchor_x, cursor.anchor_y = 1, 1
    cursor.clip_right(10)
    unittest.assert(cursor.x == 90)
    unittest.assert(cursor.y == 100)
    unittest.assert(cursor.width == 90)
    unittest.assert(cursor.height == 100)
    unittest.assert(cursor.anchor_x == 1)
    unittest.assert(cursor.anchor_y == 1)
end

function T.test_clip_bottom()
    cursor.x, cursor.y = 100, 100
    cursor.width, cursor.height = 100, 100
    cursor.anchor_x, cursor.anchor_y = 1, 1
    cursor.clip_bottom(10)
    unittest.assert(cursor.x == 100)
    unittest.assert(cursor.y == 90)
    unittest.assert(cursor.width == 100)
    unittest.assert(cursor.height == 90)
    unittest.assert(cursor.anchor_x == 1)
    unittest.assert(cursor.anchor_y == 1)
end

function T.test_h_fit_screen()
    -- must reset first for cursor to store screen dimensions
    cursor.reset()
    cursor.width = 10
    cursor.h_fit_screen()
    unittest.assert(cursor.width == screen_width)
end

function T.test_v_fit_screen()
    -- must reset first for cursor to store screen dimensions
    cursor.reset()
    cursor.height = 10
    cursor.v_fit_screen()
    unittest.assert(cursor.height == screen_height)
end

return T
