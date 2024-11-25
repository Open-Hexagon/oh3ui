--[[
    ## List of Usable State Table Fields
    Fields that are prefixed with an underscore should be treated as private to the element that's using them.
    All fields are optional
    
    * Sensor fields
    hovering boolean --- True when cursor is hovering. Read only; set automatically by the sensor module

    clicked integer --- The mouse button id that just clicked this element. Keyboard navigation will also set this value on kb_action.activate
    holding integer --- The mouse button id that is currently holding down this element

    dragging integer --- the mouse button id that is currently dragging this element
    started_dragging integer --- the mouse button id just started dragging this element
    stopped_dragging integer --- the mouse button id just stopped dragging this element
    drag_origin_x number --- the mouse x coordinate where dragging began
    drag_origin_y number --- the mouse y coordinate where dragging began

    * Element data representation
    value number --- contains whatever real numerical data the element may be representing
    position integer --- contains whatever discrete state the element may be representing
    on boolean --- contains whatever boolean data the element may be representing
    text string --- contains whatever string data the element may be representing

    * Keyboard Input Injection
    kb_selected --- True when the keyboard navigation has selected the cell associated with this state. Read only.
    kb_action --- Contains a number from kb_action if an action is requested from keyboard navigation.

    * Other fields
    initialized boolean --- may be used to keep track of first time initialization
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
