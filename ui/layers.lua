-- Handles a stack of layers

local cursor = require("ui.cursor")
local knav = require("ui.control.keyboard_navigation")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local control_method = shared_data.enums.control_method
local draw_queue = require("ui.draw_queue")
local stack_manager = require("ui.stack_manager")
local selection_outline_add_to_queue = require("ui.decorator.selection_outline").add_to_queue

--[=[
Layer changing

Layers that have interaction disabled cannot modify the layer stack so only the topmost layer can affect the stack.

PUSH: layer1 wants to push a new layer

                                                        [layer2]
                                                           v
[inter-frame] [layer1] [inter-frame [layer2] ]  [layer1]         [inter-frame]
                  \______^    \________^__________________^

- layer1 requests to push layer2
- In between frames (layer1 was the last layer):
    - Restart all control methods, pretending as if layer1 had interaction disabled.
    - Run layer2 (this rebuilds the navigation data only for layer2)
    - If keyboard nav was used, select the default or first cell of layer2.
    - Insert layer2 into the stack for the next frame.
- The next frame is run as normal.

POP: layer2 wants to pop itself off the stack

                                                      [layer2]
                                                         ^    
[inter-frame] [layer1][layer2] [inter-frame] [layer1]         [inter-frame]
                          \______^    \__________________^

- layer2 requests to pop itself.
- In between frames
    - layer2 gets removed.
    - If keyboard nav was used, select the default or first cell of layer1.
        (This is kept track of as a secondary default cell that is updated by layers below the topmost layer.)
        (Since layer2 may already have a default cell, but we just deleted and we don't want to rerun layer1 to find out what it was.)
- The next frame is run as normal.


SWAP: exchange the top layer with another
TODO : not implemented yet

]=]

local layers = {}

-- Higher index layers will show up on top of lower index layers
local stack = {}
local length = 0

local PUSH = 0
local POP = 1

local schedule_index = 0
local scheduled_tasks = {}
local scheduled_layers = {}

---Initialize the stack with some layers
---@param ... function
function layers.init(...)
    length = select("#", ...)
    for i = 1, length do
        stack[i] = select(i, ...)
    end
end

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

    if control_data.last_used_control_method == control_method.keyboard then
        -- if keyboard navigation was used we need to find the best cell to select on the new top layer
        control_data.current_layer_is_active = true
        knav.reset()
        stack[length]()
        knav.finish_layer_transition()
        stack_manager.clean_up()
    else
        -- deactivate keyboard nav if something else was used
        knav.deselect()
    end
end

---Run the functions for all the layers
function layers.run()
    -- check if layer 1 exists
    if length > 0 then
        -- run inactive layers
        for i = 1, length - 1 do
            cursor.reset()
            control_data.current_layer = i
            stack[i]()
            stack_manager.clean_up()
        end

        control_data.current_layer_is_active = true
        -- make the top layer active
        cursor.reset()
        control_data.current_layer = length
        stack[length]()
        stack_manager.clean_up()
    end

    selection_outline_add_to_queue()

    -- turn off the draw queue
    -- this also disable the addition of new mouse sensors
    draw_queue.done()

    reconfigure_layers()

    -- set this back to it's default
    control_data.current_layer_is_active = false
end

return layers
