local buffer = require("string.buffer")
local bit = require("bit")
local theme = require("ui.theme")
local band = bit.band

local ansi = {}

---Converts a color and optionally some text to an escape sequence
---@param color number[]|number can be a color table or an xterm color number
---@param text string?
---@return string
---@nodiscard
function ansi.to_sequence(color, text)
    text = text or ""
    if type(color) == "number" then
        -- 5 means 256 color mode
        return string.format("\x1b[38;5;%dm%s", color, text)
    else
        local r, g, b, a =
            band(color[1] * 255, 255), band(color[2] * 255, 255), band(color[3] * 255, 255), band(color[4] * 255, 255)

        -- 38 means set foreground color
        -- 4 means CMYK mode in the original ITU-T T.416 spec, but here we're using it for RGBA
        return string.format("\x1b[38;4;%d;%d;%d;%dm%s", r, g, b, a, text)
    end
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
    local start_pos, end_pos, mode, r, g, b, a, str, xterm_num, _
    start_pos, end_pos, mode = string.find(seq, "\x1b%[38;(%d);", init)
    if start_pos then
        init = end_pos + 1
        if mode == "4" then
            _, end_pos, r, g, b, a, str = string.find(seq, "^(%d*);(%d*);(%d*);(%d*)m([^\x1b]*)", init)
            if not end_pos then
                error("incomplete color sequence")
            end
            r = tonumber(r) or 0
            g = tonumber(g) or 0
            b = tonumber(b) or 0
            a = tonumber(a) or 0
            return { r / 255, g / 255, b / 255, a / 255 }, str, start_pos, end_pos
        elseif mode == "5" then
            _, end_pos, xterm_num, str = string.find(seq, "^(%d*)m([^\x1b]*)", init)
            if not end_pos then
                error("incomplete color sequence")
            end
            return theme.get_xterm_color(tonumber(xterm_num) --[[@as integer]]), str, start_pos, end_pos
        else
            error("bad color sequence mode " .. mode)
        end
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
    local _, end_pos, str, color
    local init_pos

    -- catch any leading text and use the default theme color
    _, end_pos, str = string.find(text, "^([^\x1b]*)")
    if end_pos > 0 then
        table.insert(coloredtext, theme.text_color)
        table.insert(coloredtext, str)
    end
    init_pos = end_pos + 1
    while true do
        color, str, _, end_pos = ansi.from_sequence(text, init_pos)
        if not color then
            break
        end
        table.insert(coloredtext, color)
        table.insert(coloredtext, str)
        init_pos = end_pos + 1
    end
    return coloredtext
end

return ansi
