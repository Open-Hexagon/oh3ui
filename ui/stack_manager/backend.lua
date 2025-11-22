local stack_data = require("ui.stack_manager.stack_data")
local warning = require("ui.warning")

local stack_manager_backend = {
    record_stack_index = 0,
}

function stack_manager_backend.clean_up()
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
        error(string.format("a(n) %s element wasn't finished properly", stack_data.aeb_stack[stack_data.aeb_index]))
    end
    if stack_manager_backend.record_stack_index > 0 then
        stack_manager_backend.record_stack_index = 0
        warning("the record stack wasn't empty at the end of frame")
    end
end

return stack_manager_backend
