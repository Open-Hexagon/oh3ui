---Primitives are elements that only use a single draw operation.

local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local text = require("ui.text")
local settings = require("ui.settings")

local primitive = {}

---Rectangle primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param mode? "fill"|"line" default is "fill"
---@param line_width number? only used in line mode
function primitive.rectangle(color, mode, line_width)
    cursor.place()
    draw_queue.rectangle(
        mode or "fill",
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        color or theme.default,
        0,
        0,
        line_width or 1
    )
end

---Rectangle outline primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param line_width number?
function primitive.rectangle_outline(color, line_width)
    cursor.place()
    draw_queue.rectangle_outline(
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        color or theme.default,
        line_width or 1,
        0,
        0
    )
end

---Slot primitive, aka a pill shape. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param mode? "fill"|"line" default is "fill"
---@param line_width number? only used in line mode
function primitive.slot(color, mode, line_width)
    local radius = math.min(cursor.width, cursor.height) / 2
    cursor.place()
    draw_queue.rectangle(
        mode or "fill",
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        color or theme.default,
        radius,
        radius,
        line_width or 1
    )
end

---Slot outline primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param line_width number?
function primitive.slot_outline(color, line_width)
    local radius = math.min(cursor.width, cursor.height) / 2
    cursor.place()
    draw_queue.rectangle_outline(
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
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
        placement.left + radius,
        placement.top + radius,
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
        placement.left + radius,
        placement.top + radius,
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
---@param size number font size in pixels
---@param align love.AlignMode alignment mode
---@param wrap boolean wrap text
---@param color number[]? override text color
---@param font_path string? override font
function primitive.label(str, size, align, wrap, color, font_path)
    cursor.push()

    -- Scale up
    local wrap_limit = wrap and (cursor.width * settings.scale) or math.huge

    local font = text.get_font(size * settings.scale, font_path or theme.font_path)

    -- get a new text object
    local text_object = text.get_text_object(font, str, wrap_limit, align)

    -- Get text size. It can change even if wrap_text is true. Scaled down this time.
    local text_width, text_height = love.graphics.inverseTransformPoint(text_object:getDimensions())

    -- A text object with an infinite wrap limit will not get drawn properly when aligned with center or right,
    -- so we replace the text_object with a a version with a finite wrap limit in those cases.
    if not wrap and align ~= "left" then
        text_object = text.get_text_object(font, str, text_width, align)
    end

    cursor.place(text_width, text_height)
    draw_queue.text(text_object, placement.left, placement.top, color or theme.text_color)

    cursor.do_auto_reshape()
end

---Creates an icon. Uses "assets/bootstrap-icons.ttf" by default. Will reshape the cursor.
---@param icon_name string icon name
---@param size number icon override icon size in pixels (works like a font)
---@param color number[]? override text color
function primitive.icon(icon_name, size, color)
    cursor.push()

    local str = text.get_icon_string(icon_name, theme.icon_font_path)
    local font = text.get_font(size * settings.scale, theme.icon_font_path)

    local text_object = text.get_text_object(font, str, math.huge, "left")

    local width, height = love.graphics.inverseTransformPoint(text_object:getDimensions())

    cursor.place(width, height)
    draw_queue.text(text_object, placement.left, placement.top, color or theme.text_color)

    cursor.do_auto_reshape()
end

---Horizontal line primitive. Never reshapes the cursor.
---The line will be placed at about cursor.y and extend from edge.left to edge.right.
---@param color number[]?
---@param line_width number?
function primitive.hline(color, line_width)
    cursor.place()
    local y = placement.y - cursor.anchor_y + 0.5
    draw_queue.line(line_width or 1, color or theme.default, placement.left, y, placement.right, y)
end

---Vertical line primitive. Never reshapes the cursor.
---The line will be placed at about cursor.x and extend from edge.top to edge.bottom.
---@param color number[]?
---@param line_width number?
function primitive.vline(color, line_width)
    cursor.place()
    local x = placement.x - cursor.anchor_x + 0.5
    draw_queue.line(line_width or 1, color or theme.default, x, placement.top, x, placement.bottom)
end

return primitive
