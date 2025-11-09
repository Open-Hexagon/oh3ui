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
    rectangle_inline = 107,

    -- special operations
    push_scissor = 201,
    pop_scissor = 202,
    mouse_sensor = 203,
    view_request_export_picture_frame = 206,

    -- overlay operations
    -- these are identical to the draw operations except that they get put at the end of the draw_list
    overlay_rectangle = 300,
    overlay_rectangle_outline = 301,
    overlay_circle = 302,
    overlay_circle_outline = 303,
    overlay_line = 304,
    overlay_polygon = 305,
    overlay_text = 306,
    overlay_rectangle_inline = 307,
}

return draw_operation
