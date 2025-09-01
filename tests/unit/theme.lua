local theme = require("ui.theme")
local unittest = require("tests.unittest")

local T = {}

function T.test_theme()
    local rectangle_color = theme.red

    unittest.assert(theme.red == rectangle_color, "color table references should match")
    theme.red = {}
    unittest.assert(theme.red ~= rectangle_color, "color table references should not match")
    theme.red = nil
    unittest.assert(theme.red == rectangle_color, "color table references should match")
end

return T
