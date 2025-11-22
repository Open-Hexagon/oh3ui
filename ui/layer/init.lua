local layer_backend = require("ui.layer.backend")
local scheduled_tasks = layer_backend.scheduled_tasks
local scheduled_layers = layer_backend.scheduled_layers

local layer = {}

---Put a layer on top of the stack
---@param layer_fn function
function layer.push(layer_fn)
    layer_backend.schedule_index = layer_backend.schedule_index + 1
    scheduled_tasks[layer_backend.schedule_index] = "push"
    scheduled_layers[layer_backend.schedule_index] = layer_fn
end

---Remove the topmost layer from the stack
function layer.pop()
    if scheduled_tasks[layer_backend.schedule_index] == "push" then
        -- if the latest scheduled task is a push, then we can just remove it to save some work later.
        scheduled_tasks[layer_backend.schedule_index] = nil
        scheduled_layers[layer_backend.schedule_index] = nil
        layer_backend.schedule_index = layer_backend.schedule_index - 1
    else
        layer_backend.schedule_index = layer_backend.schedule_index + 1
        scheduled_tasks[layer_backend.schedule_index] = "pop"
    end
end

function layer.is_current_layer_active()
    return layer_backend.current_layer_is_active
end

function layer.get_current_layer()
    return layer_backend.current_layer
end

return layer
