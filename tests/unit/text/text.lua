local unittest = require("tests.unittest")
local text = require("ui.text")

local T = {}

function T.test_get_font()
    unittest.assert_error(text.get_font, nil, 16, "none")

    local f = text.get_font(16, "assets/OpenSquare.ttf")

    unittest.assert(type(f) == "userdata")
end

function T.test_get_icon_string()
    unittest.assert_error(text.get_icon_string, nil, "check", "none")
    unittest.assert_error(text.get_icon_string, nil, "-----", "assets/bootstrap-icons.ttf")

    local s = text.get_icon_string("check", "assets/bootstrap-icons.ttf")

    unittest.assert(s == "\xef\x89\xae")
end

return T
