local scissor_stack = require("ui.scissor_stack")
local text_cache = require("ui.text_cache")
local draw_queue = {}

local queue = {}
local index = 0

local op_ids = {
    rectangle = "r",
    polygon = "p",
    push_scissor = "su",
    pop_scissor = "so",
    text = "t",
}

local placeholders = {}
local placeholder_index = 0
local index_overwrite

---adds any values as item to the queue (can overwrite old entries using index_overwrite)
---@param ... unknown
local function add_item(...)
    local idx

    if index_overwrite then
        idx = index_overwrite
        index_overwrite = nil
    else
        index = index + 1
        idx = index
    end

    queue[idx] = queue[idx] or {}
    for i = 1, math.max(select("#", ...), #queue[idx]) do
        queue[idx][i] = select(i, ...)
    end
end

---the queue command executed next will be put into the last placeholder
function draw_queue.put_next_in_last_placeholder()
    index_overwrite = placeholders[placeholder_index]
    placeholder_index = placeholder_index - 1
end

---add a placeholder to the queue
function draw_queue.placeholder()
    add_item()
    placeholder_index = placeholder_index + 1
    placeholders[placeholder_index] = index
end

---add nothing to the queue (in case a placeholder wasn't required)
function draw_queue.nothing()
    add_item()
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
    add_item(op_ids.rectangle, mode, x1, y1, x2, y2, rx or 0, ry or 0, unpack(color))
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
    add_item(op_ids.polygon, mode, unpack(polygon_data, 1, #vertices + 4))
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
    add_item(op_ids.text, text_object, x, y, unpack(color))
end

---queue pushing a scissor rectangle onto the scissor stack
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function draw_queue.push_scissor(x1, y1, x2, y2)
    x1, y1 = love.graphics.transformPoint(x1, y1)
    x2, y2 = love.graphics.transformPoint(x2, y2)
    add_item(op_ids.push_scissor, x1, y1, x2, y2)
end

---queue poping a scissor rectangle from the scissor stack
function draw_queue.pop_scissor()
    add_item(op_ids.pop_scissor)
end

---execute all queued commands
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
    -- start overwriting commands from the start next frame
    index = 0
end

return draw_queue
