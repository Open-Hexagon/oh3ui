local element = require("ui.element")
local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local theme = require("ui.theme")
local knav = require("ui.control.keyboard_navigation")
local scroll = require("ui.element.area.scroll")

local outset, line_width = element.selection_outline_outset, element.selection_outline_line_width

---A rectangular outline that is outset from the cursor
---Does not modify the cursor in any way
return function()
    cursor.push()
    cursor.outset(outset)

    cursor.area_expansion_off()
    primitive.rectangle(theme.accent_color, "line", line_width)
    cursor.area_expansion_on()

    if knav.selection_has_changed then
        scroll.scroll_into_view()
    end

    cursor.pop()
end
