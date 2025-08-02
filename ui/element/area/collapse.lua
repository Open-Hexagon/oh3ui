local cursor = require("ui.cursor")
local primitive = require("ui.primitive")

local collapse = {}

---comment
---@param state table
---@param label_str string
function collapse.start(state, label_str)
    if cursor.height <= 20 then
        error("collapse needs cursor height to be greater than 20")
    end

    cursor.change_anchor(0, 0)
    cursor.height = 20
    primitive.rectangle()

    if state._is_collapsed then
        primitive.icon("chevron-right", 16)
    else
        primitive.icon("chevron-down", 16)
    end

    cursor.x = cursor.x + 20
    cursor.width = cursor.width - 20
    primitive.label(label_str, 16, "left", false)

    cursor.start_area()
end

function collapse.finish()
    cursor.finish_area()
end

return collapse
