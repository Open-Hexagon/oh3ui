---Primitives are elements that only use a single draw operation.
---Draw queue reservations will work on these elements without the use of grouping.

local cursor = require("ui.cursor")
local edge = cursor.edge
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local ui = require("ui")
local text = require("ui.text")

local primitive = {}

---Rectangle primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param mode string? "fill" or "line" (default is "fill")
function primitive.rectangle(color, mode)
    cursor.place()
    draw_queue.rectangle(mode or "fill", edge.left, edge.top, edge.right, edge.bottom, color or theme.default)
end

---Rectangle outline primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param line_width number?
function primitive.rectangle_outline(color, line_width)
    cursor.place()
    draw_queue.rectangle_outline(edge.left, edge.top, edge.right, edge.bottom, color or theme.default, line_width or 1)
end

---Slot primitive, aka a pill shape. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param mode string? "fill" or "line" (default is "fill")
function primitive.slot(color, mode)
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

---Slot outline primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param line_width number?
function primitive.slot_outline(color, line_width)
    local radius = math.min(cursor.width, cursor.height) / 2
    cursor.place()
    draw_queue.rectangle_outline(
        edge.left,
        edge.top,
        edge.right,
        edge.bottom,
        color or theme.default,
        line_width or 1,
        radius,
        radius
    )
end

---Circle primitive. Will reshape the cursor if the cursor width and height aren't the same.
---Can also create regular polygons.
---@param color number[]? overrides the default color
---@param sides integer? create regular polygons instead
---@param rotation number? only useful if the number of sides is small
---@param mode string? "fill" or "line" (default is "fill")
function primitive.circle(color, sides, rotation, mode)
    local diameter = math.min(cursor.width, cursor.height)
    local radius = diameter / 2
    cursor.place(diameter, diameter)
    draw_queue.circle(
        mode or "fill",
        edge.left + radius,
        edge.top + radius,
        radius,
        color or theme.default,
        sides,
        rotation
    )
end

---Circle primitive. Will reshape the cursor if the cursor width and height aren't the same.
---Can also create regular polygons.
---@param color number[]? overrides the default color
---@param line_width number?
---@param sides integer? create regular polygons instead
---@param rotation number? only useful if the number of sides is small
function primitive.circle_outline(color, line_width, sides, rotation)
    local diameter = math.min(cursor.width, cursor.height)
    local radius = diameter / 2
    cursor.place(diameter, diameter)
    draw_queue.circle_outline(
        edge.left + radius,
        edge.top + radius,
        radius,
        line_width or 1,
        color or theme.default,
        sides,
        rotation
    )
end

---Creates a label. Will reshape the cursor.
---@param str string label text
---@param size number? override font size in pixels
---@param align love.AlignMode? override alignment mode
---@param color number[]? override text color
---@param font_path string? override text.font
function primitive.label(str, size, align, color, font_path)
    local font = text.get_font(size, font_path)
    local wrap_limit = cursor.wrap_text and cursor.width or math.huge
    align = align or text.align

    -- Get text size. It can change even if wrap_text is true.
    local text_width, text_height = text.get_size(str, font, wrap_limit, align)

    cursor.place(text_width, text_height)
    draw_queue.text(str, font, edge.left, edge.top, color or theme.text_color, wrap_limit, align)
end

---Creates an icon. Uses "assets/bootstrap-icons.ttf" by default. Will reshape the cursor.
---@param icon_name string icon name
---@param size number? icon override icon size in pixels (works like a font)
---@param color number[]? override text color
---@param icon_font string? override text.icon_font
function primitive.icon(icon_name, size, color, icon_font)
    icon_font = icon_font or text.icon_font
    local str = text.get_icon_string(icon_name, icon_font)
    local font = text.get_font(size, icon_font)

    local width, height = text.get_size(str, font)

    cursor.place(width, height)
    draw_queue.text(str, font, edge.left, edge.top, color or theme.text_color)
end

---Mask everything outside of the cursor. Further draw operations will not affect masked areas.
function primitive.push_mask()
    cursor.place()
    draw_queue.push_scissor(edge.left, edge.top, edge.right, edge.bottom)
end

---Removes the last applied mask.
function primitive.pop_mask()
    draw_queue.pop_scissor()
end

-- TODO

---Horizontal line primitive. Never reshapes the cursor.
---The line will be placed at cursor.y + 0.5 and extend from edge.left to edge.right.
function primitive.hline(color) end

---Vertical line primitive. Never reshapes the cursor.
---The line will be placed at cursor.x + 0.5 and extend from edge.top to edge.bottom.
function primitive.vline(color) end

return primitive
