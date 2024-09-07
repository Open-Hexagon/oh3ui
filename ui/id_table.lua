local meta = {
    __index = function(t, k)
        t[k] = {}
        return t[k]
    end,
}

---Create a new table that initializes any unknown key as empty table.
---This new table can be used to generate state tables for elements.
return function()
    return setmetatable({}, meta)
end
