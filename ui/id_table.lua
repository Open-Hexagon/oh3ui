--[[
    ## List of Usable State Table Fields
    Fields that are prefixed with an underscore should be treated as private to the element that's using them.
    Change them at your own risk as they could change fields/values without warning.

    All fields are optional
    
    * Element data representation
    value number --- contains whatever real numerical data the element may be representing
    position integer --- contains whatever discrete state the element may be representing
    on boolean --- contains whatever boolean data the element may be representing
    text string --- contains whatever string data the element may be representing

    * Other fields
    initialized boolean --- may be used to keep track of first time initialization
                            set this to false/nil to force reinitialization
                            (elements that don't require initialization don't use this field)

    * Scrolling fields
    scroll_dist_x boolean
    scroll_dist_y boolean
    scroll_vel_x boolean
    scroll_vel_y boolean
]]

local meta = {
    -- Make a new table if a previously unknown name is provided as a key
    __index = function(t, new_name)
        t[new_name] = {}
        return t[new_name]
    end,
}

---Create a new table that initializes any unknown key as empty table.
---This new table can be used to generate state tables for elements.
return function()
    return setmetatable({}, meta)
end
