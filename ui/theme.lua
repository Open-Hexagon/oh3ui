local bit = require("bit")
local extmath = require("ui.extmath")

---Converts an integer to a color table with alpha
---@param x integer
---@return number[]
local function i2a(x)
    return {
        bit.band(bit.rshift(x, 24), 0xff) / 0xff,
        bit.band(bit.rshift(x, 16), 0xff) / 0xff,
        bit.band(bit.rshift(x, 8), 0xff) / 0xff,
        bit.band(x, 0xff) / 0xff,
    }
end

---Converts an integer to a color table with alpha set to 1
---@param x integer
---@return number[]
local function i2c(x)
    return {
        bit.band(bit.rshift(x, 16), 0xff) / 0xff,
        bit.band(bit.rshift(x, 8), 0xff) / 0xff,
        bit.band(x, 0xff) / 0xff,
        1,
    }
end

---1d lerp
---@param a number[]
---@param b number[]
---@param t number
---@return number[]
local function mix(a, b, t)
    local c = {}
    for i = 1, #a do
        c[i] = extmath.lerp(a[i], b[i], t)
    end
    return c
end

-- default theme colors
local theme = {
    default = { 0.2, 0.2, 0.2, 1 }, -- default color of primitives
    text_color = { 1, 1, 1, 1 }, -- default text color

    rectangle_color = { 0.2, 0.2, 0.2, 1 },
    active_color = { 0.4, 0.4, 1, 1 },
    -- no alpha, it is animated in the code
    scrollbar_color = { 1, 1, 1 },
    grabbed_scrollbar_color = { 1, 1, 0.8, 1 },


}
theme.button_outline = i2c(0x838689)
theme.button_outline_highlight = i2c(0x3daee9)
theme.button_background = i2c(0x31363b)
theme.button_background_highlight = mix(theme.button_background, theme.button_outline_highlight, 0.5)

theme.toggle_on_background = theme.button_background_highlight
theme.toggle_off_background = theme.button_background
theme.toggle_actuator = { 0.8, 0.8, 0.8, 1 }
theme.toggle_actuator_outline = { 1, 1, 1, 1 }
theme.toggle_actuator_outline_highlight = theme.button_outline_highlight

-- export the mix function
theme.mix = mix

-- allows setting values in the table to overwrite them but restores default when set to nil
return setmetatable({}, { __index = theme })
