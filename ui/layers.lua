-- Handles a stack of layers

local cursor = require("ui.cursor")
local knav = require("ui.control.keyboard_navigation")
local mnav = require("ui.control.mouse_navigation")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local control_method = shared_data.enums.control_method

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

local PUSH = 0
local POP = 1
-- local

local task_id
---@type function
local task_layer

function layers.init(layer)
    stack[1] = layer
end

---Put a layer on top of the stack
---@param layer function
function layers.push(layer)
    if control_data.suppress_controls then
        error("layer stack can only be modified by the topmost layer")
    end
    if task_id then
        error("two layer operations cannot be made in one frame")
    end
    task_id = PUSH
    task_layer = layer
end

---Remove the topmost layer from the stack
function layers.pop()
    if control_data.suppress_controls then
        error("layer stack can only be modified by the topmost layer")
    end
    if task_id then
        error("two layer operations cannot be made in one frame")
    end
    task_id = POP
end

---Run the functions for all the layers
function layers.run()
    -- run suppressed layers
    control_data.suppress_controls = true

    local i = 1
    while stack[i + 1] do
        cursor.reset()
        stack[i]()
        i = i + 1
    end

    -- We only want the topmost layer to be interactable
    control_data.suppress_controls = false
    task_id = nil

    cursor.reset()
    stack[i]()

    if task_id == PUSH then
        -- restart navigation
        mnav.lt_restart()
        knav.lt_restart()

        -- run the new layer
        task_layer()

        -- handle keyboard stuff
        if control_data.last_used_control_method == control_method.keyboard then
            knav.lt_select_best_cell()
        else
            knav.deselect()
        end

        -- add to the stack
        stack[i + 1] = task_layer
    elseif task_id == POP then
        if i == 1 then
            error("cannot pop the bottommost layer")
        end

        stack[i] = nil

        -- handle keyboard stuff
        knav.lt_restart()
        if control_data.last_used_control_method == control_method.keyboard then
            knav.lt_select_best_cell()
        else
            knav.deselect()
        end
    end
end

return layers
