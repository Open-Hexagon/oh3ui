---Alias module for the draw queue reservation functionality

local draw_queue = require("ui.draw_queue")

local reserve = {}

reserve.allocate = draw_queue.reserve
reserve.take = draw_queue.take_reservation

return reserve
