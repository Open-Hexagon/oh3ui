-- Handles a stack of layers
local layers = {}

layers.allow_interaction = true

-- Higher index layers will show up on top of lower index layers
local index = 0
local stack = {}

---Put a layer on top of the stack
---@param layer function
function layers.push(layer)
    index = index + 1
    stack[index] = layer
end

---Remove the topmost layer from the stack
function layers.pop()
    index = index - 1
end

---Run the functions for all the layers
function layers.run()
    local cursor = require("ui.cursor")
    layers.allow_interaction = false
    for i = 1, index - 1 do
        stack[i]()
        cursor.start()
    end

    -- We only want the topmost layer to be interactable
    layers.allow_interaction = true
    stack[index]()
end

return layers
