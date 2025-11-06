---Similar to place_by_id but interface uses direct coordinate values instead of providing a placement id.
---Each of these creates it's own placement id which is returned.

local draw_data = require("ui.draw_queue.draw_data")
local place_by_id = require("ui.draw_queue.place_by_id")

local place_by_value = {}

---Pushes a mask.
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return integer placement_id
function place_by_value.push_mask(left, top, right, bottom)
    local id = draw_data.make_placement(left, top, right, bottom)
    place_by_id.push_mask(id)
    return id
end

---Add a rectangle to the queue
---@param mode love.DrawMode
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param color number[]
---@param rx number
---@param ry number
---@param line_width number
---@return integer placement_id
function place_by_value.rectangle(mode, left, top, right, bottom, color, rx, ry, line_width)
    local id = draw_data.make_placement(left, top, right, bottom)
    place_by_id.rectangle(id, mode, rx, ry, line_width, unpack(color))
    return id
end

---Add a rectangle outline to the queue (the outer edges of the drawn line matches the placement)
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param line_width number
---@param color number[]
---@param rx number
---@param ry number
---@return integer placement_id
function place_by_value.rectangle_outline(left, top, right, bottom, color, line_width, rx, ry)
    local id = draw_data.make_placement(left, top, right, bottom)
    place_by_id.rectangle_outline(id, line_width, rx, ry, unpack(color))
    return id
end

---Add a rectangle inline to the queue (the inner edges of the drawn line matches the placement)
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param line_width number
---@param color number[]
---@param rx number
---@param ry number
---@return integer placement_id
function place_by_value.rectangle_inline(left, top, right, bottom, color, line_width, rx, ry)
    local id = draw_data.make_placement(left, top, right, bottom)
    place_by_id.rectangle_inline(id, line_width, rx, ry, unpack(color))
    return id
end

---Add a circle to the queue. Can also be used to make regular polygons.
---@param mode love.DrawMode
---@param x number
---@param y number
---@param radius number
---@param color number[]
---@param line_width number
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
---@return integer point_id
function place_by_value.circle(mode, x, y, radius, color, line_width, segments, rotation)
    local id = draw_data.make_point(x, y)
    place_by_id.circle(id, mode, radius, line_width, segments, rotation, unpack(color))
    return id
end

---Add a circle outline to the queue. Can also be used to make regular polygons.
---@param x number
---@param y number
---@param radius number
---@param line_width number
---@param color number[]
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
---@return integer point_id
function place_by_value.circle_outline(x, y, radius, line_width, color, segments, rotation)
    local id = draw_data.make_point(x, y)
    place_by_id.circle_outline(id, radius, line_width, segments, rotation, unpack(color))
    return id
end

---Add a polygon to the queue
---@param mode string
---@param color number[]
---@param line_width number
---@param x1 number 1st point x coordinate
---@param y1 number 1st point y coordinate
---@param x2 number 2nd point x coordinate
---@param y2 number 2nd point y coordinate
---@param x3 number 3rd point x coordinate
---@param y3 number 3rd point y coordinate
---@param ... number
---@return integer point_cluster_id
function place_by_value.polygon(mode, color, line_width, x1, y1, x2, y2, x3, y3, ...)
    local id = draw_data.make_point_cluster(x1, y1, x2, y2, x3, y3, ...)
    place_by_id.polygon(id, mode, line_width, unpack(color))
    return id
end

---Add a multiline to the queue
---@param line_width number
---@param color number[]
---@param x1 number 1st point x coordinate
---@param y1 number 1st point y coordinate
---@param x2 number 2nd point x coordinate
---@param y2 number 2nd point y coordinate
---@param ... number more coordinates
---@return integer point_cluster_id
function place_by_value.line(line_width, color, x1, y1, x2, y2, ...)
    local id = draw_data.make_point_cluster(x1, y1, x2, y2, ...)
    place_by_id.line(id, line_width, unpack(color))
    return id
end

---Add text to the queue
---@param text_object love.Text
---@param x number
---@param y number
---@param color number[]
---@return integer point_id
function place_by_value.text(text_object, x, y, color)
    local id = draw_data.make_point(x, y)
    place_by_id.text(id, text_object, unpack(color))
    return id
end

return place_by_value
