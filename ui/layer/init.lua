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

---Keeps track of what layers are in the stack and retired list. Used to prevent duplicate pushes.
local layer_registry = {}

---Higher index layers will show up on top of lower index layers
---@type layer[]
local layer_stack = {}
local layer_stack_index = 0

---Newly retired layers appear below older ones
---@type layer[]
local retired_layers = {}
local retired_layers_index = 0

local function push_layer(layer, can_duplicate)
    if layer_registry[layer] then
        if can_duplicate then
            layer_registry[layer] = layer_registry[layer] + 1
        else
            return
        end
    else
        layer_registry[layer] = 1
    end

    layer_stack_index = layer_stack_index + 1
    layer_stack[layer_stack_index] = layer
    if layer.on_push then
        layer.on_push()
    end
end

local function pop_layer()
    if layer_stack_index == 0 then
        error("cannot pop layer: reached bottom of layer stack")
    end
    local layer = layer_stack[layer_stack_index]
    if layer.on_pop then
        layer.on_pop()
    end
    layer_registry[layer] = layer_registry[layer] - 1
    if layer_registry[layer] == 0 then
        layer_registry[layer] = nil
    end
    layer_stack[layer_stack_index] = nil
    layer_stack_index = layer_stack_index - 1
end

local function retire_layer()
    if layer_stack_index == 0 then
        error("cannot retire layer: reached bottom of layer stack")
    end
    local layer = layer_stack[layer_stack_index]
    if not layer.on_pop then
        error("retiring layers need an on_pop function")
    end

    retired_layers_index = retired_layers_index + 1
    retired_layers[retired_layers_index] = layer

    -- give on_pop a function to call to release the layer
    layer.on_pop(function()
        table.remove(retired_layers, retired_layers_index)
        retired_layers_index = retired_layers_index - 1
        layer_registry[layer] = layer_registry[layer] - 1
        if layer_registry[layer] == 0 then
            layer_registry[layer] = nil
        end
    end)

    layer_stack[layer_stack_index] = nil
    layer_stack_index = layer_stack_index - 1
end

---@type layer?
local scheduled_pinned_layer
local should_update = false
---@type layer?
local pinned_layer

local layer_manager = {}

---Put a layer on top of the stack
---@param layer layer
---@param can_duplicate boolean? if true, the layer can be pushed even if it's already on the stack
function layer_manager.push(layer, can_duplicate)
    schedule_index = schedule_index + 1
    scheduled_tasks[schedule_index] = can_duplicate and "pushd" or "push"
    scheduled_layers[schedule_index] = layer
end

---Remove the topmost layer from the stack
function layer_manager.pop()
    if scheduled_tasks[schedule_index] == "push" then
        -- if the latest scheduled task is a push, then we can just remove it to save some work later.
        -- note that this also means that on_push and on_pop are not run for that layer
        scheduled_tasks[schedule_index] = nil
        scheduled_layers[schedule_index] = nil
        schedule_index = schedule_index - 1
    else
        schedule_index = schedule_index + 1
        scheduled_tasks[schedule_index] = "pop"
    end
end

---Removes the topmost layer but keeps it running
function layer_manager.retire()
    schedule_index = schedule_index + 1
    scheduled_tasks[schedule_index] = "retire"
end

---Sets a new pinned layer
---@param layer layer?
function layer_manager.set_pinned_layer(layer)
    scheduled_pinned_layer = layer
    should_update = true
end

layer_manager.is_knav_allowed_on_current_layer = layer_status.is_knav_allowed_on_current_layer
layer_manager.is_mnav_allowed_on_current_layer = layer_status.is_mnav_allowed_on_current_layer
layer_manager.get_current_layer_number = layer_status.get_current_layer_number

---Run the functions for all the layers.
---For ohui internal use only.
function layer_manager.run_all()
    local layer_counter = 0

    layer_status.mnav_allowed = true -- mouse navigation is enabled for all active layers
    layer_status.knav_allowed = false

    -- run normal layers
    if layer_stack_index > 0 then
        -- run inactive layers
        for i = 1, layer_stack_index - 1 do
            cursor.reset()
            layer_counter = layer_counter + 1
            layer_status.current_layer_number = layer_counter
            layer_stack[i].main()
            stack_manager.clean_up()
        end

        layer_status.knav_allowed = true -- keyboard navigation is only enabled for the topmost layer
        cursor.reset()
        layer_counter = layer_counter + 1
        layer_status.current_layer_number = layer_counter
        layer_stack[layer_stack_index].main()
        stack_manager.clean_up()
    end

    layer_status.knav_allowed = false
    layer_status.mnav_allowed = false

    -- run retired layers newest to oldest
    if retired_layers_index > 0 then
        for i = retired_layers_index, 1, -1 do
            cursor.reset()
            layer_counter = layer_counter + 1
            layer_status.current_layer_number = layer_counter
            retired_layers[i].main()
            stack_manager.clean_up()
        end
    end

    -- run pinned layer
    if pinned_layer then
        cursor.reset()
        layer_counter = layer_counter + 1
        layer_status.current_layer_number = layer_counter
        pinned_layer.main()
        stack_manager.clean_up()
    end
end

---For ohui internal use only.
function layer_manager.prepare_for_next_frame()
    if schedule_index == 0 then
        return
    end

    for i = 1, schedule_index do
        if scheduled_tasks[i] == "push" then
            push_layer(scheduled_layers[i], false)
        elseif scheduled_tasks[i] == "pushd" then
            push_layer(scheduled_layers[i], true)
        elseif scheduled_tasks[i] == "pop" then
            pop_layer()
        elseif scheduled_tasks[i] == "retire" then
            retire_layer()
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
        layer_status.knav_allowed = true
        keyboard_navigation.reset()
        layer_stack[layer_stack_index].main() -- we have to run the new top layer (possibly again)
        keyboard_navigation.finish_layer_transition()
        stack_manager.clean_up()
    else
        -- deactivate keyboard nav if something else was used
        keyboard_navigation.deselect()
    end
end

return layer_manager
