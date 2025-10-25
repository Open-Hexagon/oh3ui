---Handles a queue of draw operations. All queued drawed operations will be executed at the end of the frame.
---These draw operations are lower-level bare commands and do not interact with the cursor at all.
---For nicer functions that implicitly use the cursor and color themes, see primitive.lua
---Because this is an ordered event list, it does some other things not necessarily related to drawing but require ordered execution.
---e.g. setting up the sensor z-list

local scissor_stack = require("ui.draw_queue.scissor_stack")
local extmath = require("ui.extmath")
local sensor = require("ui.control.mouse_navigation.sensor")
local warning = require("ui.warning")
local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")

local draw_queue = {}

---Add a no-operation to the queue.
---Can be used to pop the reservation stack without adding any operation.
function draw_queue.nop()
    draw_data.add_draw_operation(op_ids.nop)
end

---Add a push to the scissor stack
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return integer placement_id
function draw_queue.push_scissor(left, top, right, bottom)
    local id = draw_data.make_placement(left, top, right, bottom)
    draw_data.add_draw_operation(op_ids.push_scissor, id)
    return id
end

---Add a pop to the scissor stack
function draw_queue.pop_scissor()
    draw_data.add_draw_operation(op_ids.pop_scissor)
end

---@param n integer
function draw_queue.revert_scissor(n)
    draw_data.add_draw_operation(op_ids.revert_scissor, n)
end

---Add a mouse sensor to the draw queue.
---This will be used by the sensor module to determine which sensor is being hovered.
---The actual shape of the sensor may be changed by the scissor during execution of the draw queue.
---@param sensor_id integer
---@param mode integer
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return integer placement_id
function draw_queue.mouse_sensor(sensor_id, mode, left, top, right, bottom)
    local id = draw_data.make_placement(left, top, right, bottom)
    draw_data.add_draw_operation(op_ids.mouse_sensor, id, sensor_id, mode)
    return id
end

--#region drawing functions

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
function draw_queue.rectangle(mode, left, top, right, bottom, color, rx, ry, line_width)
    local id = draw_data.make_placement(left, top, right, bottom)
    draw_data.add_draw_operation(op_ids.rectangle, id, mode, rx, ry, line_width, unpack(color))
    return id
end

---Add a rectangle outline to the queue
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param line_width number
---@param color number[]
---@param rx number
---@param ry number
---@return integer placement_id
function draw_queue.rectangle_outline(left, top, right, bottom, color, line_width, rx, ry)
    local id = draw_data.make_placement(left, top, right, bottom)
    draw_data.add_draw_operation(op_ids.rectangle_outline, id, line_width, rx, ry, unpack(color))
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
function draw_queue.circle(mode, x, y, radius, color, line_width, segments, rotation)
    local id = draw_data.make_point(x, y)
    rotation = rotation or 0
    draw_data.add_draw_operation(
        op_ids.circle,
        id,
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
function draw_queue.circle_outline(x, y, radius, line_width, color, segments, rotation)
    local id = draw_data.make_point(x, y)
    rotation = rotation or 0
    draw_data.add_draw_operation(
        op_ids.circle_outline,
        id,
        radius,
        line_width,
        color[1],
        color[2],
        color[3],
        color[4],
        rotation,
        segments
    )
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
function draw_queue.polygon(mode, color, line_width, x1, y1, x2, y2, x3, y3, ...)
    local id = draw_data.make_point_cluster(x1, y1, x2, y2, x3, y3, ...)
    draw_data.add_draw_operation(op_ids.polygon, id, mode, line_width, color[1], color[2], color[3], color[4])
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
function draw_queue.line(line_width, color, x1, y1, x2, y2, ...)
    local id = draw_data.make_point_cluster(x1, y1, x2, y2, ...)
    draw_data.add_draw_operation(op_ids.line, id, line_width, color[1], color[2], color[3], color[4])
    return id
end

---Add text to the queue
---@param text_object love.Text
---@param x number
---@param y number
---@param color number[]
---@return integer point_id
function draw_queue.text(text_object, x, y, color)
    local id = draw_data.make_point(x, y)
    draw_data.add_draw_operation(op_ids.text, id, text_object, unpack(color))
    return id
end

--#endregion

--[[
    * Aside: How ui scaling and transformations are done 

    Old method

    apply transforms e.g. scale x2
    build the queue while passing any coordinate through transformPoint e.g x2 to all coordinate values
    undo all transforms
    draw elements using absolute coordinates (they all got scaled by x2 anyways)

    Upsides:
    - calling graphics transformations directly while building the queue works (even with weird stuff like rotate or skew).

    Downsides:
    - line widths are not scaled properly, they would have to be multiplied too.
    - May be confusing e.g. forgetting to pass coordinates through transformPoint.

    New method (currently implemented)

    apply transforms (this could go after "build queue" but we want [inverse]TransformPoint to work)
    build the queue
    draw elements with transforms
    undo transforms

    Upsides:
    - No need to remember to transform everything manually.
    - Transforms are completely accurate.

    Downsides:
    - calling graphics transformations has no effect while building the queue.
]]

---Execute all queued commands.
---This will also reset everything related to the queue
function draw_queue.draw()
    local id, x1, y1, x2, y2, mode, rx, ry, line_width, r, g, b, a, half_width, radius, rotation, segments, text_object, sensor_id
    for item in draw_data.iterate() do
        id = item[1]
        if id > op_ids.nop then
            if id == op_ids.rectangle then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                mode, rx, ry, line_width, r, g, b, a = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
            elseif id == op_ids.rectangle_outline then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                line_width, rx, ry, r, g, b, a = unpack(item, 3)
                half_width = line_width * 0.5
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(
                    "line",
                    x1 + half_width,
                    y1 + half_width,
                    x2 - x1 - line_width,
                    y2 - y1 - line_width,
                    rx,
                    ry
                )
            elseif id == op_ids.circle then
                x1, y1 = draw_data.get_point(item[2])
                mode, radius, r, g, b, a, line_width, rotation, segments = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                if rotation == 0 then
                    love.graphics.circle(mode, x1, y1, radius, segments)
                else
                    love.graphics.push()
                    love.graphics.translate(x1, y1)
                    love.graphics.rotate(rotation)
                    love.graphics.circle(mode, 0, 0, radius, segments)
                    love.graphics.pop()
                end
            elseif id == op_ids.circle_outline then
                x1, y1 = draw_data.get_point(item[2])
                radius, line_width, r, g, b, a, rotation, segments = unpack(item, 3)
                if segments then
                    -- use accurate inset
                    radius = extmath.inradius_offset(radius, segments, -0.5 * line_width)
                else
                    -- use approximation
                    radius = radius - 0.5 * line_width
                end
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                if rotation == 0 then
                    love.graphics.circle("line", x1, y1, radius, segments)
                else
                    love.graphics.push()
                    love.graphics.translate(x1, y1)
                    love.graphics.rotate(rotation)
                    love.graphics.circle("line", 0, 0, radius, segments)
                    love.graphics.pop()
                end
            elseif id == op_ids.polygon then
                mode, line_width, r, g, b, a = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.polygon(mode, draw_data.get_point_cluster(item[2]))
            elseif id == op_ids.line then
                line_width, r, g, b, a = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.line(draw_data.get_point_cluster(item[2]))
            elseif id == op_ids.text then
                x1, y1 = draw_data.get_point(item[2])
                text_object, r, g, b, a = unpack(item, 3)
                love.graphics.setColor(r, g, b, a)
                -- draw text objects without scaling for full resolution
                -- find out where the text should go after we undo the scaling
                x1, y1 = love.graphics.transformPoint(x1, y1)
                love.graphics.push()
                love.graphics.origin()
                love.graphics.draw(text_object, x1, y1)
                love.graphics.pop()

            -- * special
            elseif id == op_ids.push_scissor then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                -- scissor is not affected by graphics transforms
                x1, y1 = love.graphics.transformPoint(x1, y1)
                x2, y2 = love.graphics.transformPoint(x2, y2)
                scissor_stack.push(x1, y1, x2 - x1, y2 - y1)
            elseif id == op_ids.pop_scissor then
                scissor_stack.pop()
            elseif id == op_ids.mouse_sensor then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                sensor_id, mode = unpack(item, 3)
                local x, y, width, height = love.graphics.getScissor()

                -- sensor and mouse is not affected by graphics transforms
                x1, y1 = love.graphics.transformPoint(x1, y1)
                x2, y2 = love.graphics.transformPoint(x2, y2)

                if x then
                    x1, y1, x2, y2 = extmath.aligned_rectangle_intersection(x1, y1, x2, y2, x, y, x + width, y + height)
                    -- only push if there was an intersection
                    if x1 then
                        sensor.push(sensor_id, mode, x1, y1, x2, y2)
                    end
                else
                    -- push if there is no active scissor
                    sensor.push(sensor_id, mode, x1, y1, x2, y2)
                end
            elseif id == op_ids.revert_scissor then
                scissor_stack.revert(item[2])
            elseif id == op_ids.unused_reservation then
                warning(
                    string.format(
                        "unused reservation slot with res_id %d, slot number %d of %d\n",
                        item[2],
                        item[3],
                        item[4]
                    )
                )
            else
                -- luacov: disable
                -- should be unreachable
                error(string.format("unknown draw queue op id %d", id))
                -- luacov: enable
            end
        end
    end
end

return draw_queue
