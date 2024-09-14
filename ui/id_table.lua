local meta = {
    __index = function(t, k)
        t[k] = {}
        return t[k]
    end,
}

--[[

TODO: Standard state table fields. Establish some generic names for common states.

"on" true when the element is on (such as a toggle switch being on)

"enabled" true when the user can interact with the element

]]

---Create a new table that initializes any unknown key as empty table.
---This new table can be used to generate state tables for elements.
return function()
    return setmetatable({}, meta)
end
