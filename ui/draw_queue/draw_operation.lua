---@enum draw_operation
local draw_operation = {
    -- meta operations
    nop = 0,
    unused_reservation = 1,

    -- draw operations
    rectangle = 100,
    rectangle_outline = 101,
    circle = 102,
    circle_outline = 103,
    line = 104,
    polygon = 105,
    text = 106,

    -- special operations
    push_scissor = 201,
    pop_scissor = 202,
    mouse_sensor = 203,
    revert_scissor = 204,
}

return draw_operation
