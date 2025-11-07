---Formerly called primitive.
---Similar to place_by_value but will use the cursor to determine placement.
---These functions will create their own placements as well as place and possibly reshape the cursor.
---These functions can be treated as single operation elements.
---Some operations in place_by_cursor don't have equivalents in place_by_id or place_by_value.
---Some operations in place_by_id or place_by_value have no equivalents in place_by_cursor.

local cursor = require("ui.cursor")
local placement = cursor.placement
local place_by_value = require("ui.draw_queue.place_by_value")
local settings = require("ui.settings")
local text = require("ui.text")
local theme = require("ui.theme")
local draw_data = require("ui.draw_queue.draw_data")

local place_by_cursor = {}

---Pushes a mask.
---@return integer placement_id
function place_by_cursor.push_mask()
    cursor.place()
    return place_by_value.push_mask(placement.left, placement.top, placement.right, placement.bottom)
end

---Makes a blank placement using the cursor.
---Does not add a draw operation.
---@return integer placement_id
function place_by_cursor.blank()
    cursor.place()
    return draw_data.make_placement(placement.left, placement.top, placement.right, placement.bottom)
end

---Rectangle primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param mode? "fill"|"line" default is "fill"
---@param line_width number? only used in line mode
---@return integer placement_id
function place_by_cursor.rectangle(color, mode, line_width)
    cursor.place()
    return place_by_value.rectangle(
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
---@return integer placement_id
function place_by_cursor.rectangle_outline(color, line_width)
    cursor.place()
    return place_by_value.rectangle_outline(
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
---@return integer placement_id
function place_by_cursor.slot(color, mode, line_width)
    local radius = math.min(cursor.width, cursor.height) / 2
    cursor.place()
    return place_by_value.rectangle(
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
---@return integer placement_id
function place_by_cursor.slot_outline(color, line_width)
    local radius = math.min(cursor.width, cursor.height) / 2
    cursor.place()
    return place_by_value.rectangle_outline(
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
---@param line_width number?
---@return integer point_id
function place_by_cursor.circle(color, sides, rotation, mode, line_width)
    cursor.push()
    local diameter = math.min(cursor.width, cursor.height)
    local radius = diameter / 2
    cursor.place(diameter, diameter)
    local point_id = place_by_value.circle(
        mode or "fill",
        placement.left + radius,
        placement.top + radius,
        radius,
        color or theme.default,
        line_width or 1,
        sides,
        rotation
    )
    cursor.do_auto_reshape()
    return point_id
end

---Circle primitive. Will reshape the cursor if the cursor width and height aren't the same.
---Can also create regular polygons.
---@param color number[]? overrides the default color
---@param line_width number?
---@param sides integer? create regular polygons instead
---@param rotation number? only useful if the number of sides is small
---@return integer point_id
function place_by_cursor.circle_outline(color, line_width, sides, rotation)
    cursor.push()
    local diameter = math.min(cursor.width, cursor.height)
    local radius = diameter / 2
    cursor.place(diameter, diameter)
    local point_id = place_by_value.circle_outline(
        placement.left + radius,
        placement.top + radius,
        radius,
        line_width or 1,
        color or theme.default,
        sides,
        rotation
    )
    cursor.do_auto_reshape()
    return point_id
end

---Creates a label. Will reshape the cursor.
---@param str string label text
---@param size number font size in pixels
---@param align love.AlignMode alignment mode
---@param wrap boolean wrap text
---@param color number[]? override text color
---@param font_path string? override font
---@return integer point_id
function place_by_cursor.label(str, size, align, wrap, color, font_path)
    cursor.push()

    local cursor_width_before = cursor.width
    local wrap_limit = wrap and (cursor_width_before * settings.scale) or math.huge
    local font = text.get_font(size * settings.scale, font_path or theme.font_path)

    -- get a new text object
    local text_object = text.get_text_object(font, str, wrap_limit, align)

    -- Get text size. It can change even if wrap_text is true. Scaled down this time.
    local true_text_width, true_text_height = text_object:getDimensions()
    local text_width, text_height = love.graphics.inverseTransformPoint(true_text_width, true_text_height)

    -- A text object with an infinite wrap limit will not get drawn properly when aligned with center or right,
    -- so we replace the text_object with a a version with a finite wrap limit in those cases.
    if not wrap and align ~= "left" then
        text_object = text.get_text_object(font, str, true_text_width, align)
    end

    local x, y
    if wrap then
        ---If wrapping is used, then the the width of the entire text object is actually the wrapping limit.
        ---The actual text size has nothing to do with it. This is only noticeable in center and right align modes
        ---where the text object origin isn't at the same location as the upper-left corner of the visible text bounding box.

        cursor.place(text_width, text_height)

        local offset_contribution
        if align == "left" then
            offset_contribution = 0
        elseif align == "center" then
            offset_contribution = 0.5
        elseif align == "right" then
            offset_contribution = 1
        else
            error("bad alignment")
        end

        x = placement.left - (cursor_width_before - text_width) * offset_contribution
        y = placement.top
    else
        cursor.place(text_width, text_height)
        x, y = placement.left, placement.top
    end

    local point_id = place_by_value.text(text_object, x, y, color or theme.text_color)

    cursor.do_auto_reshape()
    return point_id
end

---Creates an icon. Uses "assets/bootstrap-icons.ttf" by default. Will reshape the cursor.
---@param icon_name string icon name
---@param size number icon override icon size in pixels (works like a font)
---@param color number[]? override text color
---@return integer point_id
function place_by_cursor.icon(icon_name, size, color)
    cursor.push()

    local str = text.get_icon_string(icon_name, theme.icon_font_path)
    local font = text.get_font(size * settings.scale, theme.icon_font_path)

    local text_object = text.get_text_object(font, str, math.huge, "left")

    local width, height = love.graphics.inverseTransformPoint(text_object:getDimensions())

    cursor.place(width, height)
    local point_id = place_by_value.text(text_object, placement.left, placement.top, color or theme.text_color)

    cursor.do_auto_reshape()
    return point_id
end

---Horizontal line primitive. Never reshapes the cursor.
---The line will be placed at about cursor.y and extend from edge.left to edge.right.
---@param color number[]?
---@param line_width number?
---@return integer point_cluster_id
function place_by_cursor.hline(color, line_width)
    cursor.place()
    local y = placement.y - cursor.anchor_y + 0.5
    return place_by_value.line(line_width or 1, color or theme.default, placement.left, y, placement.right, y)
end

---Vertical line primitive. Never reshapes the cursor.
---The line will be placed at about cursor.x and extend from edge.top to edge.bottom.
---@param color number[]?
---@param line_width number?
---@return integer point_cluster_id
function place_by_cursor.vline(color, line_width)
    cursor.place()
    local x = placement.x - cursor.anchor_x + 0.5
    return place_by_value.line(line_width or 1, color or theme.default, x, placement.top, x, placement.bottom)
end

return place_by_cursor
