local buffer = require("string.buffer")
local bit = require("bit")
local band = bit.band

local ansi = {}

---Converts colored text table to a string that embeds the color information
---@param coloredtext table
---@return string
function ansi.colored_text_to_string(coloredtext)
    local color, str, r, g, b, a
    local buf = buffer.new()
    for i = 2, #coloredtext, 2 do
        color = coloredtext[i - 1]
        str = coloredtext[i]

        r = band(color[1] * 255)
        g = band(color[2] * 255)
        b = band(color[3] * 255)
        a = band(color[4] * 255)

        -- 38 means set foreground color
        -- 4 means CMYK mode in the original ITU-T T.416 spec, but here we're using it for RGBA
        buf:putf("\x1b[38;4;%d;%d;%d;%dm%s", r, g, b, a, str)
    end
    return tostring(buf)
end


---Converts a string with embedded colors to a colored text table
---@param text string
---@return table
function ansi.string_to_colored_text(text)
    local coloredtext = {}
    local start_pos, end_pos, r, g, b, a, str
    local init_pos = 1
    repeat
        start_pos, end_pos, r, g, b, a, str =
            string.find(text, "\x1b%[38;4;(%d+);(%d+);(%d+);(%d+)m([^\x1b]*)", init_pos)
        if end_pos then
            init_pos = end_pos + 1
            table.insert(coloredtext, { r / 255, g / 255, b / 255, a / 255 })
            table.insert(coloredtext, str)
        end
    until not start_pos
    return coloredtext
end

return ansi
