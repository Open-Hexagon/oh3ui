---A module that manages stacks that are used across the module

local stack_data = require("ui.stack_data")
local warning = require("ui.warning")

local record_stack = {}
local record_stack_index = 0
local SIZEOF_RECORD = 4

local stack_manager = {}

---Makes a record of all stacks. This prevents popping of any stack entries that have been made before this function is called.
---Can be used to restore all stacks to a known state.
function stack_manager.push_record()
    record_stack_index = record_stack_index + SIZEOF_RECORD
    record_stack[record_stack_index - 3] = stack_data.cursor_base_index
    record_stack[record_stack_index - 2] = stack_data.translate_base_index
    record_stack[record_stack_index - 1] = stack_data.area_base_index
    record_stack[record_stack_index] = stack_data.aeb_base_index

    stack_data.cursor_base_index = stack_data.cursor_index
    stack_data.translate_base_index = stack_data.translate_index
    stack_data.area_base_index = stack_data.area_index
    stack_data.aeb_base_index = stack_data.aeb_index
end

---Reverts all stacks to the last record
function stack_manager.pop_record()
    if record_stack_index == 0 then
        error("no records left to pop")
    end

    stack_data.cursor_index = stack_data.cursor_base_index
    stack_data.translate_index = stack_data.translate_base_index
    stack_data.area_index = stack_data.area_base_index
    stack_data.aeb_index = stack_data.aeb_base_index

    stack_data.cursor_base_index = record_stack[record_stack_index - 3]
    stack_data.translate_base_index = record_stack[record_stack_index - 2]
    stack_data.area_base_index = record_stack[record_stack_index - 1]
    stack_data.aeb_base_index = record_stack[record_stack_index]
    record_stack_index = record_stack_index - SIZEOF_RECORD
end

function stack_manager.clean_up()
    if stack_data.cursor_index > 0 then
        stack_data.cursor_index = 0
        stack_data.cursor_base_index = 0
        warning("cursor stack was not empty")
    end
    if stack_data.translate_index > 2 then
        stack_data.translate_index = 2
        stack_data.translate_base_index = 2
        warning("translation stack was not empty")
    end
    if stack_data.area_index > 0 then
        stack_data.area_index = 0
        stack_data.area_base_index = 0
        warning("area stack was not empty")
    end
    if stack_data.aeb_index > 0 then
        -- this is enforced because not doing so would actually break stuff
        error(
            string.format("a(n) %s element wasn't finished properly", stack_data.aeb_stack[stack_data.aeb_index])
        )
    end
    if record_stack_index > 0 then
        record_stack_index = 0
        warning("the record stack wasn't empty at the end of frame")
    end
end

return stack_manager
