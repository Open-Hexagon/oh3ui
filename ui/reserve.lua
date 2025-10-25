---Alias module for the draw queue reservation functionality

local draw_data = require("ui.draw_queue.draw_data")

local reserve = {}

reserve.allocate = draw_data.reserve_draw_slots
reserve.take = draw_data.take_draw_reservation

return reserve
