local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local theme = require("ui.theme")
local element = require("ui.element")

local outset, line_width = element.selection_outline_outset, element.selection_outline_line_width

---A rectangular outline that is outset from the cursor
---Does not modify the cursor in any way
return function()
    cursor.push()
    cursor.outset(outset)
    primitive.rectangle(theme.accent_color, "line", line_width)
    cursor.pop()
end
