---A table of standard colors for the UI

local bit = require("bit")
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
local extmath = require("ui.extmath")
local text = require("ui.text")

---Converts an integer to a color table with alpha set to 1
---@param x integer
---@return number[]
---@nodiscard
local function i2c(x)
    return {
        band(rshift(x, 16), 0xff) / 0xff,
        band(rshift(x, 8), 0xff) / 0xff,
        band(x, 0xff) / 0xff,
        1,
    }
end

---1d lerp
---@param a number[]
---@param b number[]
---@param t number
---@return number[]
---@nodiscard
local function mix(a, b, t)
    local c = {}
    for i = 1, #a do
        c[i] = extmath.lerp(a[i], b[i], t)
    end
    return c
end

local theme = {}

---Gets an Xterm color by it's number.
---Reference: https://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
---@param n integer 0-255
---@return table
function theme.get_xterm_color(n)
    -- clamp number
    n = band(n, 0xff)

    -- check cache
    if theme[n + 1] then
        return theme[n + 1]
    end

    local hex
    if n == 7 then
        hex = 0xc0c0c0
    elseif n == 8 then
        hex = 0x808080
    elseif n < 16 then
        local r = band(n, 1) * 0xff0000
        local g = band(rshift(n, 1), 1) * 0x00ff00
        local b = band(rshift(n, 2), 1) * 0x0000ff
        hex = bor(r, g, b)
        if n < 8 then
            hex = band(0x808080, hex)
        end
    elseif n < 232 then
        local a = ((n - 16) % 6)
        local b = (math.floor((n - 16) / 6) % 6)
        local c = (math.floor((n - 16) / 36) % 6)
        a = a > 0 and a * 40 + 55 or 0
        b = b > 0 and b * 40 + 55 or 0
        c = c > 0 and c * 40 + 55 or 0
        hex = bor(lshift(c, 16), lshift(b, 8), a)
    else
        local brightness = 8 + (n - 232) * 10
        hex = bor(lshift(brightness, 16), lshift(brightness, 8), brightness)
    end

    local color_table = i2c(hex)
    theme[n + 1] = color_table
    return color_table
end

---Currently used text font
---@type text_font_path
theme.font_path = text.font.default

---Currently used icon font
---@type icon_font_path
theme.icon_font_path = text.icon_font.default

-- primitive colors
theme.black = theme.get_xterm_color(0)
theme.red = theme.get_xterm_color(9)
theme.green = theme.get_xterm_color(10)
theme.yellow = theme.get_xterm_color(11)
theme.blue = theme.get_xterm_color(12)
theme.magenta = theme.get_xterm_color(13)
theme.cyan = theme.get_xterm_color(14)
theme.white = theme.get_xterm_color(15)

-- standard colors
theme.default = theme.magenta -- default color of primitives
theme.text_color = theme.white -- default text color
-- theme.accent_color = i2c(0x3daee9)
theme.accent_color = i2c(0xff7321)

theme.widget_outline = i2c(0x8c8c8c)
theme.widget_outline_highlight = theme.accent_color
theme.widget_background = i2c(0x404040)
theme.widget_background_brighter = mix(theme.widget_background, theme.white, 0.2)
theme.widget_background_highlight = mix(theme.widget_background, theme.widget_outline_highlight, 0.5)
theme.widget_actuator = { 0.8, 0.8, 0.8, 1 }
theme.widget_actuator_outline = theme.white
theme.widget_actuator_outline_highlight = theme.accent_color

theme.scrollbar = { 1, 1, 1, 0.35 }
theme.grabbed_scrollbar = { 1, 1, 1, 0.6 }

-- export the mix function
theme.mix = mix

-- allows setting values in the table to overwrite them but restores default when set to nil
return setmetatable({}, { __index = theme })
