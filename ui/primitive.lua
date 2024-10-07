---Primitives are elements that only use a single draw operation.
---Draw queue reservations will work on these elements without the use of grouping.

local cursor = require("ui.cursor")
local edge = cursor.edge
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local text = require("ui.text")
local ui = require("ui")

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
    cursor.push()
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
    cursor.do_auto_reshape()
end

---Circle primitive. Will reshape the cursor if the cursor width and height aren't the same.
---Can also create regular polygons.
---@param color number[]? overrides the default color
---@param line_width number?
---@param sides integer? create regular polygons instead
---@param rotation number? only useful if the number of sides is small
function primitive.circle_outline(color, line_width, sides, rotation)
    cursor.push()
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
    cursor.do_auto_reshape()
end

---Creates a label. Will reshape the cursor.
---@param str string label text
---@param size number? override font size in pixels
---@param align love.AlignMode? override alignment mode
---@param color number[]? override text color
---@param font_path string? override text.font
function primitive.label(str, size, align, color, font_path)
    cursor.push()

    -- Scale up (math.huge causes transformPoint to choke so we just use a really big number)
    local wrap_limit = text.wrap_text and (cursor.width * ui.scale) or math.huge
    size = (size or text.font_size) * ui.scale

    local font = text.get_font(size, font_path or text.font_path)
    align = align or text.align

    -- get a new text object
    local text_object = text.get_text_object(font, str, wrap_limit, align)

    -- Get text size. It can change even if wrap_text is true. Scaled down this time.
    local text_width, text_height = love.graphics.inverseTransformPoint(text_object:getDimensions())

    cursor.place(text_width, text_height)
    draw_queue.text(text_object, edge.left, edge.top, color or theme.text_color)

    cursor.do_auto_reshape()
end

---Creates an icon. Uses "assets/bootstrap-icons.ttf" by default. Will reshape the cursor.
---@param icon_name string icon name
---@param size number? icon override icon size in pixels (works like a font)
---@param color number[]? override text color
---@param icon_font string? override text.icon_font
function primitive.icon(icon_name, size, color, icon_font)
    cursor.push()
    size = (size or text.font_size) * ui.scale
    icon_font = icon_font or text.icon_font_path
    local str = text.get_icon_string(icon_name, icon_font)
    local font = text.get_font(size, icon_font)

    local text_object = text.get_text_object(font, str, math.huge, "left")

    local width, height = love.graphics.inverseTransformPoint(text_object:getDimensions())

    cursor.place(width, height)
    draw_queue.text(text_object, edge.left, edge.top, color or theme.text_color)
    
    cursor.do_auto_reshape()
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
