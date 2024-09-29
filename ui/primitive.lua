---Primitives are elements that only use a single draw operation.
---Draw queue reservations will work on these elements.

local cursor = require("ui.cursor")
local edge = cursor.edge
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local ui = require("ui")
local text = require("ui.text")

local primitive = {}

---Rectangle primitive. Never reshapes the cursor.
---@param mode string? "fill" or "line" (default is "fill")
---@param color number[]? overrides the default color
function primitive.rectangle(mode, color)
    cursor.place()
    draw_queue.rectangle(mode or "fill", edge.left, edge.top, edge.right, edge.bottom, color or theme.default)
end

---Outline primitive. Never reshapes the cursor.
---This is a line rectangle inset by 0.5 pixels because when drawing lines at integer coordinates,
---it ends up actually drawing a 2 pixel wide line, since the line lies exactly between 2 pixels.
---@param color number[]? overrides the default color
function primitive.outline(color)
    cursor.place()
    draw_queue.rectangle(
        "line",
        edge.left + 0.5,
        edge.top + 0.5,
        edge.right - 0.5,
        edge.bottom - 0.5,
        color or theme.default
    )
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

-- TODO

---Horizontal line primitive. Never reshapes the cursor.
---The line will be placed at cursor.y + 0.5 and extend from edge.left to edge.right.
function primitive.hline(color)

end

---Vertical line primitive. Never reshapes the cursor.
---The line will be placed at cursor.x + 0.5 and extend from edge.top to edge.bottom.
function primitive.vline(color)

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

---Creates a label. Will almost certainly reshape the cursor.
---@param str string
---@param color number[]?
function primitive.label(str, color)
    -- Get text size. It can change even if wrap_text is true.
    local text_width, text_height =
        text.get_size(str, cursor.get_font(), cursor.wrap_text and cursor.width or math.huge, cursor.text_align)

    cursor.place(text_width, text_height)

    -- undo scale to render text with full resolution
    love.graphics.push()
    love.graphics.scale(1 / ui.scale, 1 / ui.scale)
    draw_queue.text(
        str,
        cursor.get_font(true),
        edge.left,
        edge.top,
        color or theme.text_color,
        cursor.wrap_text and (cursor.width * ui.scale) or math.huge,
        cursor.text_align
    )
    love.graphics.pop()
end

return primitive
