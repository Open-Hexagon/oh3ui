local monkeypatch = require("tests.monkeypatch")
local volatile_data = require("ui.shared_data").volatile
local draw_queue = require("ui.draw_queue")
local unittest = require("tests.unittest")
local stack_manager = require("ui.stack_manager")

local T = {}

local last_revert_scissor_value

function T.set_up_case()
    draw_queue.revert_scissor = monkeypatch.replace(draw_queue.revert_scissor, function(n)
        last_revert_scissor_value = n
    end)
end

function T.tear_down_case()
    draw_queue.revert_scissor = monkeypatch.get_original(draw_queue.revert_scissor)
end

function T.set_up()
    last_revert_scissor_value = nil
end

function T.tear_down()
    -- cursor snapshots
    volatile_data.cursor_index = 0 -- index of the last pushed snapshot
    volatile_data.cursor_base_index = 0

    -- cursor translations
    volatile_data.translate_index = 1 -- index of the last pushed translation
    volatile_data.translate_base_index = 1

    -- cursor areas
    volatile_data.area_index = 0 -- index of the last started area
    volatile_data.area_base_index = 0

    volatile_data.mask_index = 0 -- number of masks applied
    volatile_data.mask_base_index = 0

    -- area element balance stack for two-part area elements
    volatile_data.aeb_index = 0
    volatile_data.aeb_base_index = 0

    volatile_data.record_stack_index = 0
end

function T.test_cursor_index()
    volatile_data.cursor_index = 10

    stack_manager.push_record()

    unittest.assert(volatile_data.cursor_index == 10)
    unittest.assert(volatile_data.cursor_base_index == 10)

    volatile_data.cursor_index = 15

    stack_manager.pop_record()

    unittest.assert(volatile_data.cursor_index == 10)
    unittest.assert(volatile_data.cursor_base_index == 0)
end

function T.test_translate_index()
    volatile_data.translate_index = 10

    stack_manager.push_record()

    unittest.assert(volatile_data.translate_index == 10)
    unittest.assert(volatile_data.translate_base_index == 10)

    volatile_data.translate_index = 15

    stack_manager.pop_record()

    unittest.assert(volatile_data.translate_index == 10)
    unittest.assert(volatile_data.translate_base_index == 1)
end

function T.test_area_index()
    volatile_data.area_index = 10

    stack_manager.push_record()

    unittest.assert(volatile_data.area_index == 10)
    unittest.assert(volatile_data.area_base_index == 10)

    volatile_data.area_index = 15

    stack_manager.pop_record()

    unittest.assert(volatile_data.area_index == 10)
    unittest.assert(volatile_data.area_base_index == 0)
end

function T.test_mask_index()
    volatile_data.mask_index = 10

    stack_manager.push_record()

    unittest.assert(volatile_data.mask_index == 10)
    unittest.assert(volatile_data.mask_base_index == 10)

    stack_manager.pop_record()

    unittest.assert(type(last_revert_scissor_value) == "nil")
    unittest.assert(volatile_data.mask_index == 10)
    unittest.assert(volatile_data.mask_base_index == 0)

    stack_manager.push_record()
    volatile_data.mask_index = 15

    stack_manager.pop_record()
    unittest.assert(last_revert_scissor_value == 10)
end

function T.test_aeb_index()
    volatile_data.aeb_index = 10

    stack_manager.push_record()

    unittest.assert(volatile_data.aeb_index == 10)
    unittest.assert(volatile_data.aeb_base_index == 10)

    volatile_data.aeb_index = 15

    stack_manager.pop_record()

    unittest.assert(volatile_data.aeb_index == 10)
    unittest.assert(volatile_data.aeb_base_index == 0)
end

function T.test_record_underflow()
    unittest.assert_error(stack_manager.pop_record, "record stack should be at the bottom")
end

function T.test_clean_up()
    volatile_data.cursor_index = 1
    volatile_data.cursor_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(volatile_data.cursor_index == 0)
    unittest.assert(volatile_data.cursor_base_index == 0)

    volatile_data.translate_index = 2
    volatile_data.translate_base_index = 2
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(volatile_data.translate_index == 1)
    unittest.assert(volatile_data.translate_base_index == 1)

    volatile_data.area_index = 1
    volatile_data.area_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(volatile_data.area_index == 0)
    unittest.assert(volatile_data.area_base_index == 0)

    volatile_data.mask_index = 1
    volatile_data.mask_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(volatile_data.mask_index == 0)
    unittest.assert(volatile_data.mask_base_index == 0)
    unittest.assert(last_revert_scissor_value == 0)

    volatile_data.aeb_index = 1
    volatile_data.aeb_base_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(volatile_data.aeb_index == 0)
    unittest.assert(volatile_data.aeb_base_index == 0)

    volatile_data.record_stack_index = 1
    unittest.assert_error(stack_manager.clean_up)
    unittest.assert(volatile_data.record_stack_index == 0)
end

return T
