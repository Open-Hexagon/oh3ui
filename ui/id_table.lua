local meta = {
    -- Make a new table if a previously unknown name is provided as a key
    __index = function(t, new_name)

        ---A list of known fields
        ---@class ElementStateTable
        ---@field initialized boolean? may be used to keep track of first time initialization
        ---@field clicked integer? the mouse button id that just clicked this element
        ---@field holding integer? the mouse button id that is currently holding down this element
        ---@field dragging integer? the mouse button id that is currently dragging this element
        ---@field started_dragging integer? the mouse button id just started dragging this element
        ---@field stopped_dragging integer? the mouse button id just stopped dragging this element
        ---@field drag_origin_x number? the mouse x coordinate where dragging began
        ---@field drag_origin_y number? the mouse y coordinate where dragging began
        ---@field position integer? contains whatever discrete state the element is in
        ---@field value number? contains whatever real numerical data the element may be representing
        ---@field on boolean? contains whatever boolean data the element may be representing
        ---@field text string? contains whatever string data the element may be representing
        ---@field enter boolean? used only by sensors, true on cursor enter, read only, only accurate to the previous frame
        ---@field exit boolean? used only by sensors, true on cursor exit, read only, only accurate to the previous frame
        ---@field hovering boolean? used only by sensors. true when cursor is hovering, read only, only accurate to the previous frame
        t[new_name] = {}

        return t[new_name]
    end,
}

---Create a new table that initializes any unknown key as empty table.
---This new table can be used to generate state tables for elements.
return function()
    return setmetatable({}, meta)
end
