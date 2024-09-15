local meta = {
    -- Make a new table if a previously unknown name is provided as a key
    __index = function(t, new_name)
        -- The new table comes with some standard fields with default values
        t[new_name] = {
            enabled = true
        }
        return t[new_name]
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
