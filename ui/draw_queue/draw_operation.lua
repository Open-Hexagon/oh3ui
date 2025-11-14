---@enum draw_operation
local draw_operation = {
    -- meta operations

    nop = 0x000,
    unused_reservation = 0x001,

    -- draw operations

    rectangle = 0x100,
    rectangle_outline = 0x101,
    circle = 0x102,
    circle_outline = 0x103,
    line = 0x104,
    polygon = 0x105,
    text = 0x106,
    rectangle_inline = 0x107,

    -- special operations

    push_scissor = 0x201, -- behaves like a normal draw operation
    pop_scissor = 0x202,
    mouse_sensor = 0x203, -- behaves like a normal draw operation
    set_shader = 0x1204, -- cannot be reserved
    view_request_export_picture_frame = 0x1206, -- cannot be reserved

    -- overlay draw operations
    -- these are identical to the draw operations except that they get put at the end of the draw_list

    overlay_rectangle = 0x300,
    overlay_rectangle_outline = 0x301,
    overlay_circle = 0x302,
    overlay_circle_outline = 0x303,
    overlay_line = 0x304,
    overlay_polygon = 0x305,
    overlay_text = 0x306,
    overlay_rectangle_inline = 0x307,

    -- flags

    -- if this bit is set, bypasses the effect of next_takes_reservation
    bypass_reservation = 0x1000,
}

return draw_operation
