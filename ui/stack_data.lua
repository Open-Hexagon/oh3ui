local stack_data = {
    -- cursor snapshots
    cursor_stack = {},
    cursor_index = 0, -- index of the last pushed snapshot
    cursor_base_index = 0,

    -- cursor translations
    -- has overloaded functionality: used to make the projected_placement table and bake_translations
    translate_stack = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, -- the do-nothing translation is always here
    translate_index = 2, -- index of the last pushed translation
    translate_base_index = 2,

    -- cursor areas
    area_stack = {},
    area_index = 0, -- index of the last started area
    area_base_index = 0,

    -- area element balance stack for two-part area elements
    aeb_stack = {},
    aeb_index = 0,
    aeb_base_index = 0,
}

return stack_data
