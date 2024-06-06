local layers = {}

layers.allow_interaction = true

local index = 0
local stack = {}

---put a layer on top of the stack
---@param layer function
function layers.push(layer)
    index = index + 1
    stack[index] = layer
end

---remove the topmost layer from the stack
function layers.pop()
    index = index - 1
end

---run the functions for all the layers
function layers.run()
    local state = require("ui.state")
    layers.allow_interaction = false
    for i = 1, index - 1 do
        stack[i]()
        state.reset()
    end
    layers.allow_interaction = true
    stack[index]()
end

return layers
