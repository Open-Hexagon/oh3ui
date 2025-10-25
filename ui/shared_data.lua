---Shared data that is used across the ui. Because sometimes being able to see everything is useful.

local shared_data = {}

shared_data.enums = {}

---@enum control_methods
local control_methods = {
    none = 0,
    mouse = 1,
    keyboard = 2,
    typing = 3,
}

shared_data.enums.control_method = control_methods

shared_data.control = {
    ---The cell id that is used to check for selection and actions
    ---The cell id 0 will never be assigned normally
    ---@type integer
    current_cell_id = 0,

    ---The sensor id that will be used to check for hovering.
    ---The sensor id 0 will never be assigned normally
    ---@type integer
    current_sensor_id = 0,

    ---@type control_methods
    last_used_control_method = control_methods.none,

    ---Used to disable control functions on inactive layers.
    ---@type boolean
    current_layer_is_active = false,
    current_layer = 0,

    ---Used to disable control functions for non-interactable UI areas
    ---@type boolean
    keepout_enabled = false,
}

-- data that shouldn't survive between frames
shared_data.volatile = {
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

    -- keeps track of how many masks have been applied
    mask_stack = {}, -- this only gets used when draw_queue.draw is called
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
shared_data.static = {}

return shared_data
