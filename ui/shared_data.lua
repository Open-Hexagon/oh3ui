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

shared_data.stacks = {
    cursor_stack = {},
    cursor_index = 0, -- index of the last pushed snapshot
    cursor_base_index = 0,

    translate_stack = { { 0, 0 } }, -- the do-nothing translation is always here
    translate_index = 1, -- index of the last pushed translation
    translate_base_index = 1,

    area_stack = {},
    area_index = 0, -- index of the last started area
    area_base_index = 0,

    layer_stack = {},
    layer_index = 0,
    layer_base_index = 0,

    mask_index = 0,
    mask_base_index = 0,

    area_balance_stack = {}
}

return shared_data
