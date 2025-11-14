-- Handles a stack of layers

local cursor = require("ui.cursor")
local control_backend = require("ui.control.backend")
local draw_data_block_draw_operations = require("ui.draw_queue.draw_data").block_draw_operations
local stack_manager = require("ui.stack_manager")
local selection_outline_add_to_queue = require("ui.decorator.element.selection_outline").add_to_queue
local tooltip_reset = require("ui.decorator.element.tooltip").reset
local layer_status = require("ui.layers.status")

local layers = {}

-- Higher index layers will show up on top of lower index layers
local stack = {}
local length = 0

local PUSH = 0
local POP = 1

local schedule_index = 0
local scheduled_tasks = {}
local scheduled_layers = {}

---Put a layer on top of the stack
---@param layer function
function layers.push(layer)
    schedule_index = schedule_index + 1
    scheduled_tasks[schedule_index] = PUSH
    scheduled_layers[schedule_index] = layer
end

---Remove the topmost layer from the stack
function layers.pop()
    if scheduled_tasks[schedule_index] == PUSH then
        -- if the latest scheduled task is a push, then we can just remove it to save some work later.
        scheduled_tasks[schedule_index] = nil
        scheduled_layers[schedule_index] = nil
        schedule_index = schedule_index - 1
    else
        schedule_index = schedule_index + 1
        scheduled_tasks[schedule_index] = POP
    end
end

local function reconfigure_layers()
    if schedule_index == 0 then
        return
    end

    for i = 1, schedule_index do
        if scheduled_tasks[i] == PUSH then
            length = length + 1
            stack[length] = scheduled_layers[i]
        elseif scheduled_tasks[i] == POP then
            if length == 0 then
                error("cannot pop layer: reached bottom of layer stack")
            end
            stack[length] = nil
            length = length - 1
        else
            error("invalid layer schedule task")
        end
    end
    schedule_index = 0

    if control_backend.last_used_control_method == "keyboard" then
        -- if keyboard navigation was used we need to find the best cell to select on the new top layer
        layer_status.current_layer_is_active = true
        control_backend.keyboard_navigation_reset()
        stack[length]() -- we have to run the new top layer (possibly again)
        control_backend.keyboard_navigation_finish_layer_transition()
        stack_manager.clean_up()
    else
        -- deactivate keyboard nav if something else was used
        control_backend.keyboard_navigation_deselect()
    end
end

---Run the functions for all the layers
function layers.run()
    -- check if layer 1 exists
    if length > 0 then
        -- run inactive layers
        for i = 1, length - 1 do
            cursor.reset()
            layer_status.current_layer = i
            stack[i]()
            stack_manager.clean_up()
        end

        layer_status.current_layer_is_active = true
        -- make the top layer active
        cursor.reset()
        layer_status.current_layer = length
        stack[length]()
        stack_manager.clean_up()
    end

    -- add the selection outline if it wasn't already done by any of the area elements
    selection_outline_add_to_queue()
    tooltip_reset()

    -- turn off the draw queue
    -- this also disable the addition of new mouse sensors
    draw_data_block_draw_operations()

    reconfigure_layers()

    -- set this back to it's default
    layer_status.current_layer_is_active = false
end

return layers
