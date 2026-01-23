local stack_data = require("ui.stack_manager.stack_data")
local unittest = require("tests.unittest")
local stack_manager = require("ui.stack_manager")

local T = {}

function T.tear_down()
    -- cursor snapshots
    stack_data.cursor_index = 0 -- index of the last pushed snapshot
    stack_data.cursor_base_index = 0

    -- cursor translations
    stack_data.translate_index = 2 -- index of the last pushed translation
    stack_data.translate_base_index = 2

    -- cursor areas
    stack_data.area_index = 0 -- index of the last started area
    stack_data.area_base_index = 0

    stack_data.mask_index = 0 -- number of masks applied
    stack_data.mask_base_index = 0

    -- area element balance stack for two-part area elements
    stack_data.aeb_index = 0
    stack_data.aeb_base_index = 0

    stack_data.record_stack_index = 0
end

function T.test_cursor_index()
    stack_data.cursor_index = 10

    stack_manager.push_record()

    unittest.assert(stack_data.cursor_index == 10)
    unittest.assert(stack_data.cursor_base_index == 10)

    stack_data.cursor_index = 15

    stack_manager.pop_record()

    unittest.assert(stack_data.cursor_index == 10)
    unittest.assert(stack_data.cursor_base_index == 0)
end

function T.test_translate_index()
    stack_data.translate_index = 10

    stack_manager.push_record()

    unittest.assert(stack_data.translate_index == 10)
    unittest.assert(stack_data.translate_base_index == 10)

    stack_data.translate_index = 15

    stack_manager.pop_record()

    unittest.assert(stack_data.translate_index == 10)
    unittest.assert(stack_data.translate_base_index == 2)
end

function T.test_area_index()
    stack_data.area_index = 10

    stack_manager.push_record()

    unittest.assert(stack_data.area_index == 10)
    unittest.assert(stack_data.area_base_index == 10)

    stack_data.area_index = 15

    stack_manager.pop_record()

    unittest.assert(stack_data.area_index == 10)
    unittest.assert(stack_data.area_base_index == 0)
end

function T.test_aeb_index()
    stack_data.aeb_index = 10

    stack_manager.push_record()

    unittest.assert(stack_data.aeb_index == 10)
    unittest.assert(stack_data.aeb_base_index == 10)

    stack_data.aeb_index = 15

    stack_manager.pop_record()

    unittest.assert(stack_data.aeb_index == 10)
    unittest.assert(stack_data.aeb_base_index == 0)
end

function T.test_record_underflow()
    unittest.assert_error(stack_manager.pop_record, "record stack should be at the bottom")
end

function T.test_clean_up()
    stack_data.cursor_index = 1
    stack_data.cursor_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(stack_data.cursor_index == 0)
    unittest.assert(stack_data.cursor_base_index == 0)

    stack_data.translate_index = 6
    stack_data.translate_base_index = 6
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(stack_data.translate_index == 2)
    unittest.assert(stack_data.translate_base_index == 2)

    stack_data.area_index = 1
    stack_data.area_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(stack_data.area_index == 0)
    unittest.assert(stack_data.area_base_index == 0)

    stack_data.aeb_index = 1
    stack_data.aeb_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    stack_data.aeb_index = 0
    stack_data.aeb_base_index = 0

    stack_manager.push_record()
    unittest.assert_error(stack_manager.clean_up)
end

return T
