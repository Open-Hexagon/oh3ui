local theme = {
    rectangle_color = { 0.2, 0.2, 0.2, 1 },
    label_color = { 1, 1, 1, 1 },
    active_color = { 0.4, 0.4, 1, 1 },
    knob_color = { 0.8, 0.8, 0.8, 1 },
    -- no alpha, it is animated in the code
    scrollbar_color = { 1, 1, 1 },
    grabbed_scrollbar_color = { 1, 1, 0.8, 1 },
}

-- allows setting values in the table to overwrite them but restores default when set to nil
return setmetatable({}, { __index = theme })
