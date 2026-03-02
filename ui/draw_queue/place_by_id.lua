---Provides a nicer interface for creating draw operations than directly calling add_draw_operation.
---Placement ids of the correct type must be provided.
---This is the only interface where color can be given as 4 individual values

local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")

local place_by_id = {}

---Pushes a mask
---@param placement_id integer
function place_by_id.push_mask(placement_id)
    draw_data.add_draw_operation(op_ids.push_scissor, placement_id)
end

---Add a rectangle to the queue
---@param placement_id integer
---@param mode love.DrawMode
---@param rx number
---@param ry number
---@param line_width number
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.rectangle(placement_id, mode, rx, ry, line_width, r, g, b, a)
    draw_data.add_draw_operation(op_ids.rectangle, placement_id, mode, rx, ry, line_width, r, g, b, a)
end

---Add a rectangle outline to the queue (the outer edges of the drawn line matches the placement)
---@param placement_id integer
---@param line_width number
---@param rx number
---@param ry number
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.rectangle_outline(placement_id, line_width, rx, ry, r, g, b, a)
    draw_data.add_draw_operation(op_ids.rectangle_outline, placement_id, line_width, rx, ry, r, g, b, a)
end

---Add a rectangle inline to the queue (the inner edges of the drawn line matches the placement)
---@param placement_id integer
---@param line_width number
---@param rx number
---@param ry number
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.rectangle_inline(placement_id, line_width, rx, ry, r, g, b, a)
    draw_data.add_draw_operation(op_ids.rectangle_inline, placement_id, line_width, rx, ry, r, g, b, a)
end

---Add a circle to the queue. Can also be used to make regular polygons.
---@param point_id integer
---@param mode love.DrawMode
---@param radius number
---@param line_width number
---@param segments integer? number of sides, can be nil
---@param rotation number? only useful if the number of segments is low
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.circle(point_id, mode, radius, line_width, segments, rotation, r, g, b, a)
    rotation = rotation or 0
    draw_data.add_draw_operation(op_ids.circle, point_id, mode, radius, r, g, b, a, line_width, rotation, segments)
end

---Add a circle outline to the queue. Can also be used to make regular polygons.
---@param point_id integer
---@param radius number
---@param line_width number
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.circle_outline(point_id, radius, line_width, segments, rotation, r, g, b, a)
    rotation = rotation or 0
    draw_data.add_draw_operation(op_ids.circle_outline, point_id, radius, line_width, r, g, b, a, rotation, segments)
end

---Add a polygon to the queue
---@param point_cluster_id integer
---@param mode love.DrawMode
---@param line_width number
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.polygon(point_cluster_id, mode, line_width, r, g, b, a)
    draw_data.add_draw_operation(op_ids.polygon, point_cluster_id, mode, line_width, r, g, b, a)
end

---Add a multiline to the queue
---@param point_cluster_id integer
---@param line_width number
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.line(point_cluster_id, line_width, r, g, b, a)
    draw_data.add_draw_operation(op_ids.line, point_cluster_id, line_width, r, g, b, a)
end

---Add text to the queue
---@param point_id integer
---@param text_object love.Text
---@param r number
---@param g number
---@param b number
---@param a number
function place_by_id.text(point_id, text_object, r, g, b, a)
    draw_data.add_draw_operation(op_ids.text, point_id, text_object, r, g, b, a)
end

return place_by_id
