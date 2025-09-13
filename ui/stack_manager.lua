---A module that manages stacks that are used across the module

local volatile_data = require("ui.shared_data").volatile
local record_stack = volatile_data.record_stack
local draw_queue = require("ui.draw_queue")
local warning = require("ui.warning")

local stack_manager = {}

---Makes a record of all stacks. This prevents popping of any stack entries that have been made before this function is called.
---Can be used to restore all stacks to a known state.
function stack_manager.push_record()
    do
        local index = volatile_data.record_stack_index + 1
        record_stack[index] = record_stack[index] or {}
        local slot = record_stack[index]

        slot[1] = volatile_data.cursor_base_index
        slot[2] = volatile_data.translate_base_index
        slot[3] = volatile_data.area_base_index
        slot[4] = volatile_data.mask_base_index
        slot[5] = volatile_data.aeb_base_index

        volatile_data.record_stack_index = index
    end

    volatile_data.cursor_base_index = volatile_data.cursor_index
    volatile_data.translate_base_index = volatile_data.translate_index
    volatile_data.area_base_index = volatile_data.area_index
    volatile_data.mask_base_index = volatile_data.mask_index
    volatile_data.aeb_base_index = volatile_data.aeb_index
end

---Reverts all stacks to the last record
function stack_manager.pop_record()
    if volatile_data.record_stack_index == 0 then
        error("no records left to pop")
    end

    -- tell the draw queue that masks might not have been popped normally
    if volatile_data.mask_index ~= volatile_data.mask_base_index then
        draw_queue.revert_scissor(volatile_data.mask_base_index)
    end

    volatile_data.cursor_index = volatile_data.cursor_base_index
    volatile_data.translate_index = volatile_data.translate_base_index
    volatile_data.area_index = volatile_data.area_base_index
    volatile_data.mask_index = volatile_data.mask_base_index
    volatile_data.aeb_index = volatile_data.aeb_base_index

    do
        local index = volatile_data.record_stack_index
        local slot = record_stack[index]

        volatile_data.cursor_base_index = slot[1]
        volatile_data.translate_base_index = slot[2]
        volatile_data.area_base_index = slot[3]
        volatile_data.mask_base_index = slot[4]
        volatile_data.aeb_base_index = slot[5]

        volatile_data.record_stack_index = index - 1
    end
end

function stack_manager.clean_up()
    if volatile_data.cursor_index > 0 then
        volatile_data.cursor_index = 0
        volatile_data.cursor_base_index = 0
        warning("cursor stack was not empty")
    end
    if volatile_data.translate_index > 1 then
        volatile_data.translate_index = 1
        volatile_data.translate_base_index = 1
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
        draw_queue.revert_scissor(0)
        warning("not all masks were removed")
    end
    if volatile_data.aeb_index > 0 then
        volatile_data.aeb_index = 0
        volatile_data.aeb_base_index = 0
        warning("an area element wasn't finished")
    end
    if volatile_data.record_stack_index > 0 then
        volatile_data.record_stack_index = 0
        warning("the record stack wasn't empty at the end of frame")
    end
end

return stack_manager
