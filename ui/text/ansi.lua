local buffer = require("string.buffer")
local bit = require("bit")
local band = bit.band

local ansi = {}

---Converts a color and optionally some text to an escape sequence
---@param color number[]
---@param text string?
---@return string
---@nodiscard
function ansi.to_sequence(color, text)
    text = text or ""
    local r, g, b, a =
        band(color[1] * 255, 255), band(color[2] * 255, 255), band(color[3] * 255, 255), band(color[4] * 255, 255)

    -- 38 means set foreground color
    -- 4 means CMYK mode in the original ITU-T T.416 spec, but here we're using it for RGBA
    return string.format("\x1b[38;4;%d;%d;%d;%dm%s", r, g, b, a, text)
end

---Extracts the next escape sequence and its following text. Returns nil if none was found.
---@param seq string string to search
---@param init integer? start searching from this position
---@return number[]|nil color is nil if nothing was found
---@return string text
---@return integer start_pos
---@return integer|nil end_pos
---@nodiscard
function ansi.from_sequence(seq, init)
    local start_pos, end_pos, r, g, b, a, str = string.find(seq, "\x1b%[38;4;(%d+);(%d+);(%d+);(%d+)m([^\x1b]*)", init)
    if start_pos then
        return { r / 255, g / 255, b / 255, a / 255 }, str, start_pos, end_pos
    end
    return nil, "", 0, 0
end

---Converts colored text table to a string that embeds the color information
---@param coloredtext table
---@return string
---@nodiscard
function ansi.colored_text_to_string(coloredtext)
    local color, str
    local buf = buffer.new()
    for i = 2, #coloredtext, 2 do
        color = coloredtext[i - 1]
        str = coloredtext[i]

        buf:put(ansi.to_sequence(color, str))
    end
    return tostring(buf)
end

---Converts a string with embedded colors to a colored text table
---@param text string
---@return table
---@nodiscard
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
