---Provides a nicer interface for creating draw operations than directly calling add_draw_operation.
---Placement ids of the correct type must be provided.

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
---@param color number[]
---@param rx number
---@param ry number
---@param line_width number
function place_by_id.rectangle(placement_id, mode, color, rx, ry, line_width)
    draw_data.add_draw_operation(op_ids.rectangle, placement_id, mode, rx, ry, line_width, unpack(color))
end

---Add a rectangle outline to the queue (the outer edges of the drawn line matches the placement)
---@param placement_id integer
---@param line_width number
---@param color number[]
---@param rx number
---@param ry number
function place_by_id.rectangle_outline(placement_id, color, line_width, rx, ry)
    draw_data.add_draw_operation(op_ids.rectangle_outline, placement_id, line_width, rx, ry, unpack(color))
end

---Add a rectangle inline to the queue (the inner edges of the drawn line matches the placement)
---@param placement_id integer
---@param line_width number
---@param color number[]
---@param rx number
---@param ry number
function place_by_id.rectangle_inline(placement_id, color, line_width, rx, ry)
    draw_data.add_draw_operation(op_ids.rectangle_inline, placement_id, line_width, rx, ry, unpack(color))
end

---Add a circle to the queue. Can also be used to make regular polygons.
---@param point_id integer
---@param mode love.DrawMode
---@param radius number
---@param color number[]
---@param line_width number
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
function place_by_id.circle(point_id, mode, radius, color, line_width, segments, rotation)
    rotation = rotation or 0
    draw_data.add_draw_operation(
        op_ids.circle,
        point_id,
        mode,
        radius,
        color[1],
        color[2],
        color[3],
        color[4],
        line_width,
        rotation,
        segments
    )
end

---Add a circle outline to the queue. Can also be used to make regular polygons.
---@param point_id integer
---@param radius number
---@param line_width number
---@param color number[]
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
function place_by_id.circle_outline(point_id, radius, line_width, color, segments, rotation)
    rotation = rotation or 0
    draw_data.add_draw_operation(
        op_ids.circle_outline,
        point_id,
        radius,
        line_width,
        color[1],
        color[2],
        color[3],
        color[4],
        rotation,
        segments
    )
end

---Add a polygon to the queue
---@param point_cluster_id integer
---@param mode string
---@param color number[]
---@param line_width number
function place_by_id.polygon(point_cluster_id, mode, color, line_width)
    draw_data.add_draw_operation(
        op_ids.polygon,
        point_cluster_id,
        mode,
        line_width,
        color[1],
        color[2],
        color[3],
        color[4]
    )
end

---Add a multiline to the queue
---@param point_cluster_id integer
---@param line_width number
---@param color number[]
function place_by_id.line(point_cluster_id, line_width, color)
    draw_data.add_draw_operation(op_ids.line, point_cluster_id, line_width, color[1], color[2], color[3], color[4])
end

---Add text to the queue
---@param point_id integer
---@param text_object love.Text
---@param color number[]
function place_by_id.text(point_id, text_object, color)
    draw_data.add_draw_operation(op_ids.text, point_id, text_object, unpack(color))
end

return place_by_id
