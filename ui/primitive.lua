---Primitives are elements that only use a single draw operation.
---Draw queue reservations will work on these elements.

local cursor = require("ui.cursor")
local edge = cursor.edge
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

local primitive = {}

---Rectangle primitive. Never reshapes the cursor.
---@param mode string? "fill" or "line" (default is "fill")
---@param color number[]? overrides the default color
function primitive.rectangle(mode, color)
    cursor.place()
    draw_queue.rectangle(mode or "fill", edge.left, edge.top, edge.right, edge.bottom, color or theme.default)
end

---Slot primitive, aka a pill shape. Never reshapes the cursor.
---@param mode string? "fill" or "line" (default is "fill")
---@param color number[]? overrides the default color
function primitive.slot(mode, color)
    local radius = math.min(cursor.width, cursor.height) / 2
    cursor.place()
    draw_queue.rectangle(
        mode or "fill",
        edge.left,
        edge.top,
        edge.right,
        edge.bottom,
        color or theme.default,
        radius,
        radius
    )
end

---Circle primitive. May reshape the cursor if the cursor width and height aren't the same.
---@param mode string? "fill" or "line" (default is "fill")
---@param color number[]? overrides the default color
function primitive.circle(mode, color)
    local diameter = math.min(cursor.width, cursor.height)
    local radius = diameter / 2
    cursor.place(diameter, diameter)

    --? Is this faster than using love.graphics.circle?
    draw_queue.rectangle(
        mode or "fill",
        edge.left,
        edge.top,
        edge.right,
        edge.bottom,
        color or theme.default,
        radius,
        radius
    )
end

return primitive
