local unittest = require("tests.unittest")
local ansi = require("ui.text.ansi")

local T = {}

function T.test_to_sequence()
    unittest.assert(ansi.to_sequence({ 1, 0.5, 0, 1 }) == "\x1b[38;4;255;128;0;255m")
end

function T.test_to_sequence_ignore_extra_color_fields()
    unittest.assert(ansi.to_sequence({ 1, 0.5, 0, 1, 2, 3 }) == "\x1b[38;4;255;128;0;255m")
end

function T.test_to_sequence_oob_colors()
    unittest.assert(ansi.to_sequence({ 1, 1.5, 0, -0.5 }, "hello world") == "\x1b[38;4;255;126;0;128mhello world")
end

local color, text, start_pos, end_pos
function T.test_from_sequence()
    color, text, start_pos, end_pos = ansi.from_sequence("\x1b[38;4;12;126;0;145mhello world")
    if color then
        unittest.assert_equal_lists(color, { 12 / 255, 126 / 255, 0 / 255, 145 / 255 })
        unittest.assert(text == "hello world")
        unittest.assert(start_pos == 1)
        unittest.assert(end_pos == 31)
    else
        unittest.assert(false, "ansi.from_sequence failed to find sequence")
    end
end

function T.test_from_sequence_with_init()
    color, text, start_pos, end_pos = ansi.from_sequence(
        "\x1b[38;4;55;55;55;55mIn the beginning the Universe was created.\n"
            .. "\x1b[38;4;77;77;77;77mThis has made a lot of people very angry and been widely regarded as a bad move.\n",
        50
    )
    if color then
        unittest.assert_equal_lists(color, { 77 / 255, 77 / 255, 77 / 255, 77 / 255 })
        unittest.assert(text == "This has made a lot of people very angry and been widely regarded as a bad move.\n")
        unittest.assert(start_pos == 63)
        unittest.assert(end_pos == 162)
    else
        unittest.assert(false, "ansi.from_sequence failed to find sequence")
    end
end

function T.test_from_sequence_no_sequence()
    color, text, start_pos, end_pos =
        ansi.from_sequence("The ships hung in the sky in much the same way that bricks don't.")

    unittest.assert(color == nil)
end

function T.test_colored_text_to_string()
    unittest.assert(
        ansi.colored_text_to_string({
            { 0, 0.5, 1, 1 },
            "In the beginning the Universe was created.\n",
            { 1, 0.5, 0, 1 },
            "This has made a lot of people very angry and been widely regarded as a bad move.\n",
        })
            == "\x1b[38;4;0;128;255;255mIn the beginning the Universe was created.\n"
                .. "\x1b[38;4;255;128;0;255mThis has made a lot of people very angry and been widely regarded as a bad move.\n"
    )
end

function T.test_string_to_colored_text()
    local ct = ansi.string_to_colored_text(
        "\x1b[38;4;55;55;55;55mIn the beginning the Universe was created.\n"
            .. "\x1b[38;4;77;77;77;77mThis has made a lot of people very angry and been widely regarded as a bad move.\n"
    )

    unittest.assert(#ct == 4)
    unittest.assert(type(ct[1]) == "table")
    unittest.assert_equal_lists(ct[1], { 55 / 255, 55 / 255, 55 / 255, 55 / 255 })
    unittest.assert(ct[2] == "In the beginning the Universe was created.\n")
    unittest.assert(type(ct[3]) == "table")
    unittest.assert_equal_lists(ct[3], { 77 / 255, 77 / 255, 77 / 255, 77 / 255 })
    unittest.assert(ct[4] == "This has made a lot of people very angry and been widely regarded as a bad move.\n")
end

return T
