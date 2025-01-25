local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local theme = require("ui.theme")
local decorator = require("ui.decorator")

local outset, line_width = decorator.selection_outline_outset, decorator.selection_outline_line_width

---A rectangular outline that is outset from the cursor
---Does not modify the cursor in any way
return function()
    cursor.push()
    cursor.outset(outset)
    primitive.rectangle(theme.accent_color, "line", line_width)
    cursor.pop()
end
