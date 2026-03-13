local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")

local draw_queue = {
    -- only user facing api endpoints should be visible from this table

    by_id = require("ui.draw_queue.place_by_id"),
    by_value = require("ui.draw_queue.place_by_value"),
    by_cursor = require("ui.draw_queue.place_by_cursor"),

    allocate_reservation = draw_data.reserve_draw_slots,
    close_reservation = draw_data.close_reservation,
    next_takes_reservation = draw_data.next_takes_reservation,
    next_as_overlay = draw_data.next_as_overlay,

    make_placement = draw_data.make_placement,
    get_placement = draw_data.get_placement,
    dup_placement = draw_data.dup_placement,
    edit_placement = draw_data.edit_placement,
    make_point = draw_data.make_point,
    get_point = draw_data.get_point,
    make_point_cluster = draw_data.make_point_cluster,
    get_point_cluster = draw_data.get_point_cluster,
}

function draw_queue.pop_mask()
    draw_data.add_draw_operation(op_ids.pop_scissor)
end

function draw_queue.nop()
    draw_data.add_draw_operation(op_ids.nop)
end

---@param shader love.Shader?
function draw_queue.set_shader(shader)
    draw_data.add_draw_operation(op_ids.set_shader, shader)
end

return draw_queue
