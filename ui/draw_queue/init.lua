local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")

local draw_queue = {
    by_id = require("ui.draw_queue.place_by_id"),
    by_value = require("ui.draw_queue.place_by_value"),
    by_cursor = require("ui.draw_queue.place_by_cursor"),
}

draw_queue.allocate_reservation = draw_data.reserve_draw_slots
draw_queue.next_takes_reservation = draw_data.next_takes_reservation

draw_queue.next_as_overlay = draw_data.next_as_overlay

function draw_queue.pop_mask()
    draw_data.add_draw_operation(op_ids.pop_scissor)
end

function draw_queue.nop()
    draw_data.add_draw_operation(op_ids.nop)
end

draw_queue.make_placement = draw_data.make_placement
draw_queue.get_placement = draw_data.get_placement
draw_queue.make_point = draw_data.make_point
draw_queue.get_point = draw_data.get_point
draw_queue.make_point_cluster = draw_data.make_point_cluster
draw_queue.get_point_cluster = draw_data.get_point_cluster

return draw_queue
