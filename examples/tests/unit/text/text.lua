local unittest = require("tests.unittest")
local text = require("ui.text")

local T = {}

local font = "assets/open-pentagon.ttf"

function T.test_get_font()
    unittest.assert_error(text.get_font, nil, 16, "none")

    local f = text.get_font(16, font)

    unittest.assert(type(f) == "userdata")
end

function T.test_get_icon_string()
    unittest.assert_error(text.get_icon_string, nil, "check", "none")
    unittest.assert_error(text.get_icon_string, nil, "-----", font)

    local s = text.get_icon_string("check", font)

    unittest.assert(s == "\xee\x85\xad")
end

return T
