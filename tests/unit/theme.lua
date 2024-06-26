local theme = require("ui.theme")
local test = {}

test.sequence = coroutine.create(function()
    local rectangle_color = theme.rectangle_color
    assert(theme.rectangle_color == rectangle_color, "color table references should match")
    theme.rectangle_color = {}
    assert(theme.rectangle_color ~= rectangle_color, "color table references should not match")
    theme.rectangle_color = nil
    assert(theme.rectangle_color == rectangle_color, "color table references should match")
end)

return test
