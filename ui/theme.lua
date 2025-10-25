---A table of standard colors for the UI

local bit = require("bit")
local band, rshift = bit.band, bit.rshift
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

---Currently used text font
---@type text_font_path
theme.font_path = text.font.default

---Currently used icon font
---@type icon_font_path
theme.icon_font_path = text.icon_font.default

-- primitive colors
theme.black = { 0, 0, 0, 1 }
theme.red = { 1, 0, 0, 1 }
theme.yellow = { 1, 1, 0, 1 }
theme.green = { 0, 1, 0, 1 }
theme.cyan = { 0, 1, 1, 1 }
theme.blue = { 0, 0, 1, 1 }
theme.magenta = { 1, 0, 1, 1 }
theme.white = { 1, 1, 1, 1 }

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
