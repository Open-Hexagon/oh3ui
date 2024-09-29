local cursor = require("ui.cursor")
local theme = require("ui.theme")
local ui = require("ui")
local draw_queue = require("ui.draw_queue")
local text = require("ui.text")

---Creates a label. This element will move the cursor.
---Text Wrapping: If cursor.wrap_text is true, the text will be wrapped using the cursor width.
---Text Placement: An anchor point for the text bounding box that is the same as the
---cursor is used to place the text. This point is set to exactly the cursor (x,y)
---Cursor movement: The cursor is moved first, then placed last.
---@param str string
return function(str)
    -- Get text size. It can change even if wrap_text is true.
    local text_width, text_height = text.get_size(
        str,
        cursor.get_font(),
        cursor.wrap_text and cursor.width or math.huge,
        cursor.text_align
    )

    -- undo scale to render text with full resolution
    love.graphics.push()
    love.graphics.scale(1 / ui.scale, 1 / ui.scale)
    draw_queue.text(
        str,
        cursor.get_font(true),
        cursor.x - text_width * cursor.anchor_x,
        cursor.y - text_height * cursor.anchor_y,
        theme.label_text,
        cursor.wrap_text and (cursor.width * ui.scale) or math.huge,
        cursor.text_align
    )
    love.graphics.pop()

    cursor.width, cursor.height = text_width, text_height
    cursor.place()
end
