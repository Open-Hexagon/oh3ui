local theme = require("ui.theme")
local unittest = require("tests.unittest")
local buffer = require("string.buffer")

local T = {}

function T.test_theme()
    local rectangle_color = theme.red

    unittest.assert(theme.red == rectangle_color, "color table references should match")
    theme.red = {}
    unittest.assert(theme.red ~= rectangle_color, "color table references should not match")
    theme.red = nil
    unittest.assert(theme.red == rectangle_color, "color table references should match")
end

function T.test_xterm_colors()
    local f = io.open("tests/unit/theme/xterm_colors_lut", "r")
    if not f then
        error("could not read xterm_colors_lut file")
    end
    local lut = buffer.decode(f:read("*a"))
    if not lut then
        error("could not decode xterm_colors_lut file")
    end
    for i = 0, 255 do
        unittest.assert_equal_lists(lut[i], theme.get_xterm_color(i))
        unittest.assert_equal_lists(lut[i], theme[i + 1])
    end
    f:close()
end

function T.test_alpha_mod_unpack()
    local r, g, b, a, a2
    math.randomseed(42)
    for _ = 1, 10 do
        r = math.random()
        g = math.random()
        b = math.random()
        a = math.random()
        a2 = math.random()

        unittest.assert_equal_lists({ theme.alpha_mod_unpack({ r, g, b, a }, a2) }, { r, g, b, a2 })
    end
end

return T
