---Shared variables for control modules

local shared = {
    ---The cell id that is used to check for selection and actions
    ---The cell id 0 will never be assigned normally
    ---@type integer
    current_cell_id = 0,

    ---The sensor id that will be used to check for hovering.
    ---Sensor id 0 will never be assigned normally
    ---@type integer
    current_sensor_id = 0,
}

return shared
