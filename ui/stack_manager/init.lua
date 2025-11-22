---A module that manages stacks that are used across the module

local stack_manager_backend = require("ui.stack_manager.backend")
local stack_data = require("ui.stack_manager.stack_data")

local record_stack = {}
local SIZEOF_RECORD = 4

local stack_manager = {}

---Makes a record of all stacks. This prevents popping of any stack entries that have been made before this function is called.
---Can be used to restore all stacks to a known state.
function stack_manager.push_record()
    stack_manager_backend.record_stack_index = stack_manager_backend.record_stack_index + SIZEOF_RECORD
    record_stack[stack_manager_backend.record_stack_index - 3] = stack_data.cursor_base_index
    record_stack[stack_manager_backend.record_stack_index - 2] = stack_data.translate_base_index
    record_stack[stack_manager_backend.record_stack_index - 1] = stack_data.area_base_index
    record_stack[stack_manager_backend.record_stack_index] = stack_data.aeb_base_index

    stack_data.cursor_base_index = stack_data.cursor_index
    stack_data.translate_base_index = stack_data.translate_index
    stack_data.area_base_index = stack_data.area_index
    stack_data.aeb_base_index = stack_data.aeb_index
end

---Reverts all stacks to the last record
function stack_manager.pop_record()
    if stack_manager_backend.record_stack_index == 0 then
        error("no records left to pop")
    end

    stack_data.cursor_index = stack_data.cursor_base_index
    stack_data.translate_index = stack_data.translate_base_index
    stack_data.area_index = stack_data.area_base_index
    stack_data.aeb_index = stack_data.aeb_base_index

    stack_data.cursor_base_index = record_stack[stack_manager_backend.record_stack_index - 3]
    stack_data.translate_base_index = record_stack[stack_manager_backend.record_stack_index - 2]
    stack_data.area_base_index = record_stack[stack_manager_backend.record_stack_index - 1]
    stack_data.aeb_base_index = record_stack[stack_manager_backend.record_stack_index]
    stack_manager_backend.record_stack_index = stack_manager_backend.record_stack_index - SIZEOF_RECORD
end

return stack_manager
