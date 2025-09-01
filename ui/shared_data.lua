---Shared data that is used across the ui. Because sometimes being able to see everything is useful.

local shared_data = {}

shared_data.control = {
    ---The cell id that is used to check for selection and actions
    ---The cell id 0 will never be assigned normally
    ---@type integer
    current_cell_id = 0,

    ---The sensor id that will be used to check for hovering.
    ---Sensor id 0 will never be assigned normally
    ---@type integer
    current_sensor_id = 0,
}

-- data that shouldn't survive between frames
shared_data.volatile = {
    -- cursor snapshots
    cursor_stack = {},
    cursor_index = 0, -- index of the last pushed snapshot
    cursor_base_index = 0,

    -- cursor translations
    translate_stack = { { 0, 0 } }, -- the do-nothing translation is always here
    translate_index = 1, -- index of the last pushed translation
    translate_base_index = 1,

    -- cursor areas
    area_stack = {},
    area_index = 0, -- index of the last started area
    area_base_index = 0,

    -- keeps track of how many masks have been applied
    mask_stack = {}, -- this only gets used when draw_queue.draw is called
    -- this has overloaded funcionality as both mask.lua and scissor_stack.lua use this
    mask_index = 0, -- number of masks applied
    mask_base_index = 0,

    -- area element balance stack for two-part area elements
    aeb_stack = {},
    aeb_index = 0,
    aeb_base_index = 0,

    record_stack = {},
    record_stack_index = 0,
}

-- data that survives between frames
shared_data.static = {

}

return shared_data
