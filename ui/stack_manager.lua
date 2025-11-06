---A module that manages stacks that are used across the module

local volatile_data = require("ui.shared_data").volatile
local warning = require("ui.warning")
local draw_data_add_draw_operation = require("ui.draw_queue.draw_data").add_draw_operation
local op_ids = require("ui.draw_queue.draw_operation")

local record_stack = {}
local record_stack_index = 0

local stack_manager = {}

---Makes a record of all stacks. This prevents popping of any stack entries that have been made before this function is called.
---Can be used to restore all stacks to a known state.
function stack_manager.push_record()
    record_stack_index = record_stack_index + 5
    record_stack[record_stack_index - 4] = volatile_data.cursor_base_index
    record_stack[record_stack_index - 3] = volatile_data.translate_base_index
    record_stack[record_stack_index - 2] = volatile_data.area_base_index
    record_stack[record_stack_index - 1] = volatile_data.mask_base_index
    record_stack[record_stack_index] = volatile_data.aeb_base_index

    volatile_data.cursor_base_index = volatile_data.cursor_index
    volatile_data.translate_base_index = volatile_data.translate_index
    volatile_data.area_base_index = volatile_data.area_index
    volatile_data.mask_base_index = volatile_data.mask_index
    volatile_data.aeb_base_index = volatile_data.aeb_index
end

---Reverts all stacks to the last record
function stack_manager.pop_record()
    if record_stack_index == 0 then
        error("no records left to pop")
    end

    -- tell the draw queue that masks might not have been popped normally
    if volatile_data.mask_index ~= volatile_data.mask_base_index then
        draw_data_add_draw_operation(op_ids.revert_scissor, volatile_data.mask_base_index)
    end

    volatile_data.cursor_index = volatile_data.cursor_base_index
    volatile_data.translate_index = volatile_data.translate_base_index
    volatile_data.area_index = volatile_data.area_base_index
    volatile_data.mask_index = volatile_data.mask_base_index
    volatile_data.aeb_index = volatile_data.aeb_base_index

    volatile_data.cursor_base_index = record_stack[record_stack_index - 4]
    volatile_data.translate_base_index = record_stack[record_stack_index - 3]
    volatile_data.area_base_index = record_stack[record_stack_index - 2]
    volatile_data.mask_base_index = record_stack[record_stack_index - 1]
    volatile_data.aeb_base_index = record_stack[record_stack_index]
    record_stack_index = record_stack_index - 5
end

function stack_manager.clean_up()
    if volatile_data.cursor_index > 0 then
        volatile_data.cursor_index = 0
        volatile_data.cursor_base_index = 0
        warning("cursor stack was not empty")
    end
    if volatile_data.translate_index > 2 then
        volatile_data.translate_index = 2
        volatile_data.translate_base_index = 2
        warning("translation stack was not empty")
    end
    if volatile_data.area_index > 0 then
        volatile_data.area_index = 0
        volatile_data.area_base_index = 0
        warning("area stack was not empty")
    end
    if volatile_data.mask_index > 0 then
        volatile_data.mask_index = 0
        volatile_data.mask_base_index = 0
        draw_data_add_draw_operation(op_ids.revert_scissor, 0)
        warning("not all masks were removed")
    end
    if volatile_data.aeb_index > 0 then
        -- this is enforced because not doing so would actually break stuff
        error(
            string.format("a(n) %s element wasn't finished properly", volatile_data.aeb_stack[volatile_data.aeb_index])
        )
    end
    if record_stack_index > 0 then
        record_stack_index = 0
        warning("the record stack wasn't empty at the end of frame")
    end
end

return stack_manager
