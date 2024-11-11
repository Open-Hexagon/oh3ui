---Handles a queue of draw operations. All queued drawed operations will be executed at the end of the frame.
---These draw operations are lower-level bare commands and do not interact with the cursor at all.
---For nicer functions that implicitly use the cursor and color themes, see primitive.lua
---Because this is an ordered event list, it does some other things not necessarily related to drawing but require ordered execution.
---e.g. setting up the sensor z-list

local scissor_stack = require("ui.draw_queue.scissor_stack")
local extmath = require("ui.extmath")
local sensor = require("ui.sensor")
local draw_queue = {}

local op_ids = {
    -- special operations
    push_scissor = 0,
    pop_scissor = 1,
    call_group = 2,
    mouse_sensor = 3,

    -- operations that draw stuff
    rectangle = 100,
    rectangle_outline = 101,
    circle = 102,
    circle_outline = 103,
    line = 104,
    polygon = 105,
    text = 106,
}

-- A list of groups
local groups = {}
-- Holds the index of the current group. Equal to 1 after initialization. Group 1 is the root group.
local current_group_index = 0
-- Holds the index of the last created group. Equal to 1 after initialization.
local last_group_index = 0

---Pushes an operation to the current group. The first value should be an operation id.
---This operation id can be nil which will cause the operation to be ignored.
---@param ... any
local function push_operation(...)
    local current_group = groups[current_group_index]
    local queue = current_group.op_list

    local slot_index

    if current_group.take_reservation then
        -- take a reservation
        slot_index = current_group.take_reservation
        current_group.take_reservation = nil
    else
        current_group.op_index = current_group.op_index + 1
        slot_index = current_group.op_index
    end

    queue[slot_index] = queue[slot_index] or {}
    for i = 1, math.max(select("#", ...), #queue[slot_index]) do
        queue[slot_index][i] = select(i, ...)
    end
end

---Begin a group of draw queue operations. Groups are treated as a single draw operations.
function draw_queue.begin_group()
    -- save the current group index so we can come back
    local return_index = current_group_index

    -- set up a new group
    last_group_index = last_group_index + 1
    local new_group = groups[last_group_index]

    if new_group then
        -- reset the new group
        new_group.op_index = 0
        new_group.reserve_index = 0
        new_group.return_index = return_index
        new_group.take_reservation = nil
    else
        -- this new group has never been made before
        new_group = {
            -- The list of draw operations in this group
            op_list = {},
            -- Holds the index of the last item in the op_list. Equals 0 if it's empty.
            op_index = 0,
            -- the reservation stack
            reservations = {},
            -- Holds the index of the topmost item in the reservation stack. Equals 0 if it's empty.
            reserve_index = 0,
            -- Holds the index of the reservation that the next draw operation should take.
            take_reservation = nil,
            -- The index of the group to return to when this group is ended. If it's 0, then it's the root group.
            return_index = return_index,
        }
        groups[last_group_index] = new_group
    end

    current_group_index = last_group_index
end

---End a group of draw queue operations
function draw_queue.end_group()
    -- save where we returned from
    local from_group_index = current_group_index

    local current_group = groups[current_group_index]

    -- warn if not all reservations were taken from this group
    if current_group.reserve_index ~= 0 or current_group.take_reservation then
        print(string.format("warning: not all reservations were taken in group %d after ending", from_group_index))
    end

    -- get were we're returning to
    local return_group_index = current_group.return_index

    if return_group_index == 0 then
        error("no more groups to end!")
    end

    -- return and push an operation to call the group we just ended
    current_group_index = return_group_index
    push_operation(op_ids.call_group, from_group_index)
end

---resets the group list to its initial state
local function reset_groups()
    current_group_index = 0
    last_group_index = 0
    draw_queue.begin_group()
end

-- do initial group setup
reset_groups()

---Reserves the next, single draw operation to be filled in later.
---This reservation is pushed to the reservations stack.
function draw_queue.reserve()
    push_operation()
    local current_group = groups[current_group_index]
    current_group.reserve_index = current_group.reserve_index + 1
    current_group.reservations[current_group.reserve_index] = current_group.op_index
end

---The next executed draw operation will fill in the last single reserved slot.
---The reservation on the top of the reservations stack is popped.
---Only works on a single draw operation. Use groups to have multiple operations take the place of one reservation.
function draw_queue.take_last_reservation()
    local current_group = groups[current_group_index]
    if current_group.reserve_index == 0 then
        error(string.format("no more reservations to take in group %d", current_group_index))
    end
    current_group.take_reservation = current_group.reservations[current_group.reserve_index]
    current_group.reserve_index = current_group.reserve_index - 1
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
---@param state table
---@param mode "block"|"lazy"|"pass"
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param update_fn? function
function draw_queue.mouse_sensor(state, mode, left, top, right, bottom, update_fn)
    push_operation(op_ids.mouse_sensor, state, mode, left, top, right, bottom, update_fn)
end

--#region functions that actually draw things

---Add a rectangle to the queue
---@param mode love.DrawMode
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param color number[]
---@param rx number?
---@param ry number?
function draw_queue.rectangle(mode, left, top, right, bottom, color, rx, ry)
    rx, ry = rx or 0, ry or 0
    push_operation(op_ids.rectangle, mode, left, top, right, bottom, rx, ry, unpack(color))
end

---Add a rectangle outline to the queue
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param line_width number
---@param color number[]
---@param rx number?
---@param ry number?
function draw_queue.rectangle_outline(left, top, right, bottom, color, line_width, rx, ry)
    rx, ry = rx or 0, ry or 0
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

-- local operation = {}

-- function operation.rectangle(item)
--     local mode, x1, y1, x2, y2, rx, ry, r, g, b, a = unpack(item, 2)
--     love.graphics.setColor(r, g, b, a)
--     love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
-- end

-- function operation.polygon(item)
--     love.graphics.setColor(item[3], item[4], item[5], item[6])
--     love.graphics.polygon(item[2], unpack(item, 7))
-- end

-- function operation.push_scissor(item)
--     local x1, y1, x2, y2 = unpack(item, 2)
--     -- scissor operates on screen space coordinates so we have to manually transform
--     x1, y1 = love.graphics.transformPoint(x1, y1)
--     x2, y2 = love.graphics.transformPoint(x2, y2)
--     scissor_stack.push(x1, y1, x2 - x1, y2 - y1)
-- end

-- operation.pop_scissor = scissor_stack.pop

-- function operation.text(item)
--     local text_object, x, y, r, g, b, a = unpack(item, 2)
--     love.graphics.setColor(r, g, b, a)
--     -- draw text objects without scaling for full resolution
--     -- we have to manually transform (x, y)
--     x, y = love.graphics.transformPoint(x, y)
--     love.graphics.push()
--     love.graphics.origin()
--     love.graphics.draw(text_object, x, y)
--     love.graphics.pop()
-- end

---Executes all draw operations in order specified by group_index.
---Uses recursion to handle groups calls.
---@param group_index integer the group to run
local function run_draw_operations(group_index)
    local current_group = groups[group_index]
    for i = 1, current_group.op_index do
        local item = current_group.op_list[i]
        local id = item[1]
        -- id may be nil if a placeholder was left in / nothing was appended
        if id then
            if id == op_ids.rectangle then
                local mode, x1, y1, x2, y2, rx, ry, r, g, b, a = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
            elseif id == op_ids.polygon then
                love.graphics.setColor(item[3], item[4], item[5], item[6])
                love.graphics.polygon(item[2], unpack(item, 7))
            elseif id == op_ids.push_scissor then
                local x1, y1, x2, y2 = unpack(item, 2)
                -- scissor is not affected by graphics transforms
                x1, y1 = love.graphics.transformPoint(x1, y1)
                x2, y2 = love.graphics.transformPoint(x2, y2)
                scissor_stack.push(x1, y1, x2 - x1, y2 - y1)
            elseif id == op_ids.pop_scissor then
                scissor_stack.pop()
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
            elseif id == op_ids.call_group then
                -- recursive call to group
                run_draw_operations(item[2])
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
            elseif id == op_ids.mouse_sensor then
                local state, mode, x1, y1, x2, y2, update_fn = unpack(item, 2)
                local x, y, width, height = love.graphics.getScissor()

                -- sensor and mouse is not affected by graphics transforms
                x1, y1 = love.graphics.transformPoint(x1, y1)
                x2, y2 = love.graphics.transformPoint(x2, y2)

                if x then
                    x1, y1, x2, y2 = extmath.aligned_rectangle_intersection(x1, y1, x2, y2, x, y, x + width, y + height)
                    -- only push if there was an intersection
                    if x1 then
                        sensor.push(state, mode, x1, y1, x2, y2, update_fn)
                    end
                else
                    -- push if there is no active scissor
                    sensor.push(state, mode, x1, y1, x2, y2, update_fn)
                end
            end
        end
    end
end

---Execute all queued commands.
---This will also reset everything related to the queue
function draw_queue.draw()
    -- ensure all groups are ended
    if current_group_index ~= 1 then
        error("not all groups were ended")
    end

    -- warn if not all reservations were taken
    local current_group = groups[current_group_index]
    if current_group.reserve_index ~= 0 or current_group.take_reservation then
        print(string.format("warning: not all reservations were taken in root group 1 before drawing"))
    end

    run_draw_operations(1)
    reset_groups()
end

return draw_queue
