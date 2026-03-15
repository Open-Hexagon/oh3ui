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
---@nodiscard
function place_by_cursor.blank()
    cursor.place()
    return draw_data.make_placement(placement.left, placement.top, placement.right, placement.bottom)
end

---Rectangle primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param mode? "fill"|"line" default is "fill"
---@param line_width number? only used in line mode
---@param rx number?
---@param ry number?
---@return integer placement_id
function place_by_cursor.rectangle(color, mode, line_width, rx, ry)
    cursor.place()
    return place_by_value.rectangle(
        mode or "fill",
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        color or theme.default,
        rx or 0,
        ry or 0,
        line_width or 1
    )
end

---Rectangle outline primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param line_width number?
---@param rx number?
---@param ry number?
---@return integer placement_id
function place_by_cursor.rectangle_outline(color, line_width, rx, ry)
    cursor.place()
    return place_by_value.rectangle_outline(
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        color or theme.default,
        line_width or 1,
        rx or 0,
        ry or 0
    )
end

---Rectangle inline primitive. Never reshapes the cursor.
---@param color number[]? overrides the default color
---@param line_width number?
---@param rx number?
---@param ry number?
---@return integer placement_id
function place_by_cursor.rectangle_inline(color, line_width, rx, ry)
    cursor.place()
    return place_by_value.rectangle_inline(
        placement.left,
        placement.top,
        placement.right,
        placement.bottom,
        color or theme.default,
        line_width or 1,
        rx or 0,
        ry or 0
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
---@param mode? "fill"|"line" "fill" or "line" (default is "fill")
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
    local font = text.get_font(size * settings.scale, font_path)

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
---@param font_path string? override font
---@return integer point_id
function place_by_cursor.icon(icon_name, size, color, font_path)
    cursor.push()

    local str = text.get_icon_string(icon_name, font_path)
    local font = text.get_font(size * settings.scale, font_path)

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
---@param position number? override position in cursor placement
---@return integer point_cluster_id
function place_by_cursor.hline(color, line_width, position)
    position = position or cursor.anchor_y
    line_width = line_width or 1
    cursor.place()
    local y
    if position then
        y = placement.top + (placement.bottom - placement.top - line_width) * position + 0.5 * line_width
    else
        y = placement.y + (0.5 - cursor.anchor_y) * line_width
    end
    return place_by_value.line(line_width, color or theme.default, placement.left, y, placement.right, y)
end

---Vertical line primitive. Never reshapes the cursor.
---The line will be placed at about cursor.x and extend from edge.top to edge.bottom.
---@param color number[]?
---@param line_width number?
---@param position number? override position in cursor placement
---@return integer point_cluster_id
function place_by_cursor.vline(color, line_width, position)
    position = position or cursor.anchor_x
    line_width = line_width or 1
    cursor.place()
    local x
    if position then
        x = placement.left + (placement.right - placement.left - line_width) * position + 0.5 * line_width
    else
        x = placement.x + (0.5 - cursor.anchor_x) * line_width
    end
    return place_by_value.line(line_width, color or theme.default, x, placement.top, x, placement.bottom)
end

local function v_line_edge(color, line_width, mode, base, dir, inset)
    line_width = line_width or 1
    inset = inset or 0
    local x
    if mode == "outside" then
        x = base - 0.5 * line_width * dir
    elseif mode == "center" then
        x = base
    else
        x = base + 0.5 * line_width * dir
    end
    return place_by_value.line(
        line_width,
        color or theme.default,
        x,
        placement.top + inset,
        x,
        placement.bottom - inset
    )
end

---Draws a line on the left edge of the cursor. Never reshapes the cursor.
---@param color number[]?
---@param line_width number?
---@param mode? "inside"|"outside"|"center"
---@param inset number?
---@return integer
function place_by_cursor.left_line(color, line_width, mode, inset)
    cursor.place()
    return v_line_edge(color, line_width, mode, placement.left, 1, inset)
end

---Draws a line on the right edge of the cursor. Never reshapes the cursor.
---@param color number[]?
---@param line_width number?
---@param mode? "inside"|"outside"|"center"
---@param inset number?
---@return integer
function place_by_cursor.right_line(color, line_width, mode, inset)
    cursor.place()
    return v_line_edge(color, line_width, mode, placement.right, -1, inset)
end

---Draws a vertical line in the center of the cursor. Never reshapes the cursor.
---@param color number[]?
---@param line_width number?
---@param inset number?
---@return integer
function place_by_cursor.v_center_line(color, line_width, inset)
    cursor.place()
    return v_line_edge(color, line_width, "center", placement.left + (placement.right - placement.left) * 0.5, 1, inset)
end

local function h_line_edge(color, line_width, mode, base, dir, inset)
    line_width = line_width or 1
    inset = inset or 0
    local y
    if mode == "outside" then
        y = base - 0.5 * line_width * dir
    elseif mode == "center" then
        y = base
    else
        y = base + 0.5 * line_width * dir
    end
    return place_by_value.line(
        line_width,
        color or theme.default,
        placement.left + inset,
        y,
        placement.right - inset,
        y
    )
end

---Draws a line on the top edge of the cursor. Never reshapes the cursor.
---@param color number[]?
---@param line_width number?
---@param mode? "inside"|"outside"|"center"
---@param inset number?
---@return integer
function place_by_cursor.top_line(color, line_width, mode, inset)
    cursor.place()
    return h_line_edge(color, line_width, mode, placement.top, 1, inset)
end

---Draws a line on the bottom edge of the cursor. Never reshapes the cursor.
---@param color number[]?
---@param line_width number?
---@param mode? "inside"|"outside"|"center"
---@param inset number?
---@return integer
function place_by_cursor.bottom_line(color, line_width, mode, inset)
    cursor.place()
    return h_line_edge(color, line_width, mode, placement.bottom, -1, inset)
end

---Draws a horizontal line in the center of the cursor. Never reshapes the cursor.
---@param color number[]?
---@param line_width number?
---@param inset number?
---@return integer
function place_by_cursor.h_center_line(color, line_width, inset)
    cursor.place()
    return h_line_edge(color, line_width, "center", placement.top + (placement.bottom - placement.top) * 0.5, 1, inset)
end

return place_by_cursor
