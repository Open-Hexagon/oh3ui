local meta = {
    __index = function(t, k)
        t[k] = {}
        return t[k]
    end
}

---create a new table that initializes any unknown key as empty table
return function()
    return setmetatable({}, meta)
end
