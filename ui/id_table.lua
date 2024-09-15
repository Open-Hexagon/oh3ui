local meta = {
    -- Make a new table if a previously unknown name is provided as a key
    __index = function(t, new_name)
        ---@class ElementStateTable
        ---@field initialized boolean may be used to keep track of first time initialization
        ---@field enabled boolean true when the user can interact with the element
        ---@field clicked integer? contains the mouse button id that clicked this element
        ---@field primed integer? contains the mouse button id that is primed to click this element
        ---@field value any contains whatever data the element may be representing
        t[new_name] = {
            initialized = false,
            enabled = true,
        }
        return t[new_name]
    end,
}

---Create a new table that initializes any unknown key as empty table.
---This new table can be used to generate state tables for elements.
return function()
    return setmetatable({}, meta)
end
