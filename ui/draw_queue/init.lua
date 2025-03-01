---Handles a queue of draw operations. All queued drawed operations will be executed at the end of the frame.
---These draw operations are lower-level bare commands and do not interact with the cursor at all.
---For nicer functions that implicitly use the cursor and color themes, see primitive.lua
---Because this is an ordered event list, it does some other things not necessarily related to drawing but require ordered execution.
---e.g. setting up the sensor z-list

local scissor_stack = require("ui.draw_queue.scissor_stack")
local extmath = require("ui.extmath")
local sensor = require("ui.control.mouse_navigation.sensor")

local draw_queue = {}

local op_ids = {
    -- special operations
    push_scissor = 0,
    pop_scissor = 1,
    mouse_sensor = 2,

    -- operations that draw stuff
    rectangle = 100,
    rectangle_outline = 101,
    circle = 102,
    circle_outline = 103,
    line = 104,
    polygon = 105,
    text = 106,
}

---List of draw operations
local op_list = {}
---Hold the index of the last pushed draw operation
local op_index = 0
---List of reservations
local res_list = {}
---Holds the index of the last created reservation
local res_index = 0
---If set, the next push_operation will be written at the index this variable contains
local take_reservation = nil

---Pushes an operation to the current group. The first value should be an operation id.
---This operation id can be nil which will cause the operation to be ignored.
---@param ... any
local function push_operation(...)
    local slot_index

    if take_reservation then
        -- take a reservation
        slot_index = take_reservation
        take_reservation = nil
    else
        op_index = op_index + 1
        slot_index = op_index
    end

    op_list[slot_index] = op_list[slot_index] or {}
    for i = 1, math.max(select("#", ...), #op_list[slot_index]) do
        op_list[slot_index][i] = select(i, ...)
    end
end

---Reserves the next n draw operations. It is undefined behavior if not all reservations are properly taken later.
---@param n integer number of reservations, defaults to 1
---@return integer res_id use this reference id to later fill in reservation slots
---@nodiscard
function draw_queue.reserve(n)
    if n < 1 then
        error("can't reserve less than 1 slot")
    end

    -- reservation start and stop points
    local start, stop = op_index, op_index + n

    res_index = res_index + 1
    local res = res_list[res_index]
    if res then
        res.next = start
        res.stop = stop
    else
        res = { next = start, stop = stop }
        res_list[res_index] = res
    end

    -- just increment the op_index, maybe leaving a gap
    op_index = stop

    return res_index
end

---The next operation will fill in a slot in a reservation
---@param res_id integer the reservation id to fill
function draw_queue.take_reservation(res_id)
    local res = res_list[res_id]

    if not res then
        error("Bad reservation id")
    end
    if res.next == res.stop then
        error("Reservation is full")
    end

    res.next = res.next + 1
    take_reservation = res.next
end

---Add a no-operation to the queue.
---Can be used to pop the reservation stack without adding any operation.
function draw_queue.nop()
    push_operation()
end

---Add a push to the scissor stack
---@param left number
---@param top number
---@param right number
---@param bottom number
function draw_queue.push_scissor(left, top, right, bottom)
    push_operation(op_ids.push_scissor, left, top, right, bottom)
end

---Add a pop to the scissor stack
function draw_queue.pop_scissor()
    push_operation(op_ids.pop_scissor)
end

---Add a mouse sensor to the draw queue.
---This will be used by the sensor module to determine which sensor is being hovered.
---The actual shape of the sensor may be changed by the scissor during execution of the draw queue.
---@param sensor_id integer
---@param mode "block"|"lazy"|"pass"
---@param left number
---@param top number
---@param right number
---@param bottom number
function draw_queue.mouse_sensor(sensor_id, mode, left, top, right, bottom)
    push_operation(op_ids.mouse_sensor, sensor_id, mode, left, top, right, bottom)
end

--#region functions that actually draw things

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
function draw_queue.rectangle(mode, left, top, right, bottom, color, rx, ry, line_width)
    push_operation(op_ids.rectangle, mode, left, top, right, bottom, rx, ry, line_width, unpack(color))
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
function draw_queue.rectangle_outline(left, top, right, bottom, color, line_width, rx, ry)
    push_operation(op_ids.rectangle_outline, left, top, right, bottom, line_width, rx, ry, unpack(color))
end

---Add a circle to the queue. Can also be used to make regular polygons.
---@param mode love.DrawMode
---@param x number
---@param y number
---@param radius number
---@param color number[]
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
function draw_queue.circle(mode, x, y, radius, color, segments, rotation)
    rotation = rotation or 0
    push_operation(op_ids.circle, mode, x, y, radius, color[1], color[2], color[3], color[4], rotation, segments)
end

---Add a circle outline to the queue. Can also be used to make regular polygons.
---@param x number
---@param y number
---@param radius number
---@param line_width number
---@param color number[]
---@param segments integer? number of sides
---@param rotation number? only useful if the number of segments is low
function draw_queue.circle_outline(x, y, radius, line_width, color, segments, rotation)
    rotation = rotation or 0
    push_operation(
        op_ids.circle_outline,
        x,
        y,
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
---@param mode string
---@param color number[]
---@param ... number
function draw_queue.polygon(mode, color, ...)
    push_operation(op_ids.polygon, mode, color[1], color[2], color[3], color[4], ...)
end

---Add text to the queue
---@param text_object love.Text
---@param x number
---@param y number
---@param color number[]
function draw_queue.text(text_object, x, y, color)
    push_operation(op_ids.text, text_object, x, y, unpack(color))
end

---Add a multiline to the queue
---@param line_width number
---@param color number[]
---@param x1 number first point x coordinate
---@param y1 number first point y coordinate
---@param x2 number second point x coordinate
---@param y2 number second point y coordinate
---@param ... number more coordinates
function draw_queue.line(line_width, color, x1, y1, x2, y2, ...)
    push_operation(op_ids.line, line_width, color[1], color[2], color[3], color[4], x1, y1, x2, y2, ...)
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
    - calling graphics transformations has no affect while building the queue.
]]

---Execute all queued commands.
---This will also reset everything related to the queue
function draw_queue.draw()
    for i = 1, op_index do
        local item = op_list[i]

        if not item then
            error("Encountered a gap in the draw queue caused by bad reservation management")
        end

        local id = item[1]
        -- id may be nil if a placeholder was left in / nothing was appended
        if id then
            if id == op_ids.rectangle then
                local mode, x1, y1, x2, y2, rx, ry, line_width, r, g, b, a = unpack(item, 2, 13)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
            elseif id == op_ids.rectangle_outline then
                local x1, y1, x2, y2, line_width, rx, ry, r, g, b, a = unpack(item, 2)
                local half_width = line_width * 0.5
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
                local mode, x, y, radius, r, g, b, a, rotation, segments = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                if rotation == 0 then
                    love.graphics.circle(mode, x, y, radius, segments)
                else
                    love.graphics.push()
                    love.graphics.translate(x, y)
                    love.graphics.rotate(rotation)
                    love.graphics.circle(mode, 0, 0, radius, segments)
                    love.graphics.pop()
                end
            elseif id == op_ids.circle_outline then
                local x, y, radius, line_width, r, g, b, a, rotation, segments = unpack(item, 2)
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
                    love.graphics.circle("line", x, y, radius, segments)
                else
                    love.graphics.push()
                    love.graphics.translate(x, y)
                    love.graphics.rotate(rotation)
                    love.graphics.circle("line", 0, 0, radius, segments)
                    love.graphics.pop()
                end
            elseif id == op_ids.line then
                local line_width, r, g, b, a = unpack(item, 2, 6)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.line(unpack(item, 7))
            elseif id == op_ids.polygon then
                love.graphics.setColor(item[3], item[4], item[5], item[6])
                love.graphics.polygon(item[2], unpack(item, 7))
            elseif id == op_ids.text then
                local text_object, x, y, r, g, b, a = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                -- draw text objects without scaling for full resolution
                -- find out where the text should go after we undo the scaling
                x, y = love.graphics.transformPoint(x, y)
                love.graphics.push()
                love.graphics.origin()
                love.graphics.draw(text_object, x, y)
                love.graphics.pop()

            -- * special
            elseif id == op_ids.push_scissor then
                local x1, y1, x2, y2 = unpack(item, 2)
                -- scissor is not affected by graphics transforms
                x1, y1 = love.graphics.transformPoint(x1, y1)
                x2, y2 = love.graphics.transformPoint(x2, y2)
                scissor_stack.push(x1, y1, x2 - x1, y2 - y1)
            elseif id == op_ids.pop_scissor then
                scissor_stack.pop()
            elseif id == op_ids.mouse_sensor then
                local sensor_id, mode, x1, y1, x2, y2 = unpack(item, 2)
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
            end
        end
    end

    -- cleanup
    op_index = 0
    res_index = 0
    take_reservation = nil
end

return draw_queue
