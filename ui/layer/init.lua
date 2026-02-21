local layer_status = require("ui.layer.status")
local cursor = require("ui.cursor")
local control_data = require("ui.control.control_data")
local stack_manager = require("ui.stack_manager")
local keyboard_navigation = require("ui.control.keyboard_navigation")

---@alias layer {
---  main: function,
---  on_push: function?,
---  on_pop: function?,
---}

local schedule_index = 0
local scheduled_tasks = {}
---@type layer[]
local scheduled_layers = {}

-- Higher index layers will show up on top of lower index layers
---@type layer[]
local layer_stack = {}
local layer_stack_index = 0

---@type layer?
local scheduled_pinned_layer
local should_update = false
---@type layer?
local pinned_layer

local layer_manager = {}

---Put a layer on top of the stack
---@param layer layer
function layer_manager.push(layer)
    schedule_index = schedule_index + 1
    scheduled_tasks[schedule_index] = "push"
    scheduled_layers[schedule_index] = layer
end

---Remove the topmost layer from the stack
function layer_manager.pop()
    if scheduled_tasks[schedule_index] == "push" then
        -- if the latest scheduled task is a push, then we can just remove it to save some work later.
        scheduled_tasks[schedule_index] = nil
        scheduled_layers[schedule_index] = nil
        schedule_index = schedule_index - 1
    else
        schedule_index = schedule_index + 1
        scheduled_tasks[schedule_index] = "pop"
    end
end

---Sets a new pinned layer
---@param layer layer?
function layer_manager.set_pinned_layer(layer)
    scheduled_pinned_layer = layer
    should_update = true
end

layer_manager.is_current_layer_active = layer_status.is_current_layer_active
layer_manager.get_current_layer = layer_status.get_current_layer

---Run the functions for all the layers
function layer_manager.run_all()
    layer_status.current_layer_is_active = false

    -- check if layer 1 exists
    if layer_stack_index > 0 then
        -- run inactive layers
        for i = 1, layer_stack_index - 1 do
            cursor.reset()
            layer_status.current_layer = i
            layer_stack[i].main()
            stack_manager.clean_up()
        end

        layer_status.current_layer_is_active = true
        -- make the top layer active
        cursor.reset()
        layer_status.current_layer = layer_stack_index
        layer_stack[layer_stack_index].main()
        stack_manager.clean_up()
    end

    if pinned_layer then
        layer_status.current_layer_is_active = false
        cursor.reset()
        layer_status.current_layer = -1
        pinned_layer.main()
        stack_manager.clean_up()
    end
end

function layer_manager.prepare_for_next_frame()
    if schedule_index == 0 then
        return
    end

    local layer
    for i = 1, schedule_index do
        if scheduled_tasks[i] == "push" then
            layer_stack_index = layer_stack_index + 1
            layer = scheduled_layers[i]
            if layer.on_push then
                layer.on_push()
            end
            layer_stack[layer_stack_index] = layer
        elseif scheduled_tasks[i] == "pop" then
            if layer_stack_index == 0 then
                error("cannot pop layer: reached bottom of layer stack")
            end
            layer = layer_stack[layer_stack_index]
            if layer.on_pop then
                layer.on_pop()
            end
            layer_stack[layer_stack_index] = nil
            layer_stack_index = layer_stack_index - 1
        else
            error("invalid layer schedule task")
        end
    end
    schedule_index = 0

    if should_update then
        if pinned_layer and pinned_layer.on_pop then
            pinned_layer.on_pop()
        end
        if scheduled_pinned_layer and scheduled_pinned_layer.on_push then
            scheduled_pinned_layer.on_push()
        end
        pinned_layer = scheduled_pinned_layer
        should_update = false
    end

    if control_data.get_last_used_control_method() == "keyboard" then
        -- if keyboard navigation was used we need to find the best cell to select on the new top layer
        layer_status.current_layer_is_active = true
        keyboard_navigation.reset()
        layer_stack[layer_stack_index]() -- we have to run the new top layer (possibly again)
        keyboard_navigation.finish_layer_transition()
        stack_manager.clean_up()
    else
        -- deactivate keyboard nav if something else was used
        keyboard_navigation.deselect()
    end
end

return layer_manager
