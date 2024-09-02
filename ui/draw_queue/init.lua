local scissor_stack = require("ui.draw_queue.scissor_stack")
local text_cache = require("ui.text_cache")
local draw_queue = {}

---Queue of draw operations. A place in the queue is referred to as a "slot".
local queue = {}
local index = 0

local op_ids = {
    rectangle = 0,
    polygon = 1,
    push_scissor = 2,
    pop_scissor = 3,
    text = 4,
}

---Stack of reservations
local reservations = {}
local reserve_index = 0

---Holds the index of the reservation that the next draw operation should take.
---Is nil otherwise.
local take_reservation

---Pushes a table to the queue. The first value should be an operation id.
---This operation id can be nil which will cause the operation to be ignored.
---@param ... unknown
local function push_operation(...)
    local slot_index

    if take_reservation then
        -- take a reservation
        slot_index = take_reservation
        take_reservation = nil
    else
        index = index + 1
        slot_index = index
    end

    queue[slot_index] = queue[slot_index] or {}
    for i = 1, math.max(select("#", ...), #queue[slot_index]) do
        queue[slot_index][i] = select(i, ...)
    end
end

---Reserves the next draw operation to be filled in later.
---This reservation is pushed to the reservations stack.
function draw_queue.reserve()
    push_operation()
    reserve_index = reserve_index + 1
    reservations[reserve_index] = index
end

---The next executed draw operation will fill in the last reserved slot.
---The reservation on the top of the reservations stack is popped.
function draw_queue.take_last_reservation()
    take_reservation = reservations[reserve_index]
    reserve_index = reserve_index - 1
end

---Add a no-operation to the queue.
---Can be used to pop the reservation stack without adding any operation.
function draw_queue.nop()
    push_operation()
end

---add a rectangle to the queue
---@param mode love.DrawMode
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param color table
---@param rx number?
---@param ry number?
function draw_queue.rectangle(mode, left, top, right, bottom, color, rx, ry)
    local x1, y1 = love.graphics.transformPoint(left, top)
    local x2, y2 = love.graphics.transformPoint(right, bottom)
    rx, ry = love.graphics.transformPoint(rx or 0, ry or 0)
    push_operation(op_ids.rectangle, mode, x1, y1, x2, y2, rx, ry, unpack(color))
end

local polygon_data = {}

---add a polygon to the queue
---@param mode string
---@param vertices table
---@param color table
function draw_queue.polygon(mode, vertices, color)
    for i = 1, #vertices, 2 do
        polygon_data[i], polygon_data[i + 1] = love.graphics.transformPoint(vertices[i], vertices[i + 1])
    end
    for i = 1, 4 do
        polygon_data[#vertices + i] = color[i]
    end
    push_operation(op_ids.polygon, mode, unpack(polygon_data, 1, #vertices + 4))
end

---get size of text before rendering
---@param text string
---@param font love.Font
---@param wraplimit number?
---@param align love.AlignMode?
---@return number
---@return number
function draw_queue.get_text_size(text, font, wraplimit, align)
    local text_object = text_cache.get(font, text, wraplimit or math.huge, align or "left")
    return text_object:getDimensions()
end

---add text to the queue
---@param text string
---@param font love.Font
---@param x number
---@param y number
---@param color table
---@param wraplimit number?
---@param align love.AlignMode?
function draw_queue.text(text, font, x, y, color, wraplimit, align)
    x, y = love.graphics.transformPoint(x, y)
    local text_object = text_cache.get(font, text, wraplimit or math.huge, align or "left")
    push_operation(op_ids.text, text_object, x, y, unpack(color))
end

---queue pushing a scissor rectangle onto the scissor stack
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function draw_queue.push_scissor(x1, y1, x2, y2)
    x1, y1 = love.graphics.transformPoint(x1, y1)
    x2, y2 = love.graphics.transformPoint(x2, y2)
    push_operation(op_ids.push_scissor, x1, y1, x2, y2)
end

---queue poping a scissor rectangle from the scissor stack
function draw_queue.pop_scissor()
    push_operation(op_ids.pop_scissor)
end

---Execute all queued commands.
---This will also reset everything related to the queue
function draw_queue.draw()
    for i = 1, index do
        local item = queue[i]
        local id = item[1]
        -- id may be nil if a placeholder was left in / nothing was appended
        if id then
            if id == op_ids.rectangle then
                local mode, x1, y1, x2, y2, rx, ry, r, g, b, a = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
            elseif id == op_ids.polygon then
                local len = #item
                love.graphics.setColor(unpack(item, len - 3, len))
                love.graphics.polygon(item[2], unpack(item, 3, len - 4))
            elseif id == op_ids.text then
                local text_object, x, y, r, g, b, a = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                love.graphics.draw(text_object, x, y)
            elseif id == op_ids.push_scissor then
                local x1, y1, x2, y2 = unpack(item, 2)
                scissor_stack.push(x1, y1, x2 - x1, y2 - y1)
            elseif id == op_ids.pop_scissor then
                scissor_stack.pop()
            end
        end
    end

    -- Start overwriting commands from the start next frame
    index = 0

    -- Ensure all reservations were taken
    if reserve_index ~= 0 then
        print("warning: not all reservations were taken")
        reserve_index = 0
    end

    -- Ensure the scissor stack is empty
    scissor_stack.finish()
end

return draw_queue
