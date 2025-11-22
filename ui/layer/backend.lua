-- Handles a stack of layers

local cursor = require("ui.cursor")
local control_backend = require("ui.control.backend")
local stack_manager_backend = require("ui.stack_manager.backend")

local layer_backend = {
    schedule_index = 0,
    scheduled_tasks = {},
    scheduled_layers = {},
    current_layer_is_active = false,
    current_layer = 0,
}

-- Higher index layers will show up on top of lower index layers
local stack = {}
local length = 0

---Run the functions for all the layers
function layer_backend.run_all()
    layer_backend.current_layer_is_active = false

    -- check if layer 1 exists
    if length > 0 then
        -- run inactive layers
        for i = 1, length - 1 do
            cursor.reset()
            layer_backend.current_layer = i
            stack[i]()
            stack_manager_backend.clean_up()
        end

        layer_backend.current_layer_is_active = true
        -- make the top layer active
        cursor.reset()
        layer_backend.current_layer = length
        stack[length]()
        stack_manager_backend.clean_up()
    end
end

function layer_backend.prepare_for_next_frame()
    if layer_backend.schedule_index == 0 then
        return
    end

    for i = 1, layer_backend.schedule_index do
        if layer_backend.scheduled_tasks[i] == "push" then
            length = length + 1
            stack[length] = layer_backend.scheduled_layers[i]
        elseif layer_backend.scheduled_tasks[i] == "pop" then
            if length == 0 then
                error("cannot pop layer: reached bottom of layer stack")
            end
            stack[length] = nil
            length = length - 1
        else
            error("invalid layer schedule task")
        end
    end
    layer_backend.schedule_index = 0

    if control_backend.last_used_control_method == "keyboard" then
        -- if keyboard navigation was used we need to find the best cell to select on the new top layer
        layer_backend.current_layer_is_active = true
        control_backend.keyboard_navigation_reset()
        stack[length]() -- we have to run the new top layer (possibly again)
        control_backend.keyboard_navigation_finish_layer_transition()
        stack_manager_backend.clean_up()
    else
        -- deactivate keyboard nav if something else was used
        control_backend.keyboard_navigation_deselect()
    end
end

return layer_backend
