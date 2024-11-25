local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local theme = require("ui.theme")

---A rectangular outline that is outset from the cursor
---Does not modify the cursor in any way
return function()
    cursor.push()
    cursor.outset(4)
    primitive.rectangle(theme.accent_color, "line", 2)
    cursor.pop()
end
