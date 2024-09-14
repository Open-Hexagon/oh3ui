local bit = require("bit")

---Converts an integer to a color table.
---@param x integer
---@return table
local function i2c(x)
    return {
        bit.band(bit.rshift(x, 24), 0xff) / 0xff,
        bit.band(bit.rshift(x, 16), 0xff) / 0xff,
        bit.band(bit.rshift(x, 8), 0xff) / 0xff,
        bit.band(x, 0xff) / 0xff,
    }
end

-- default theme colors
local theme = {
    rectangle_color = { 0.2, 0.2, 0.2, 1 },
    label_text = { 1, 1, 1, 1 },
    active_color = { 0.4, 0.4, 1, 1 },
    knob_color = { 0.8, 0.8, 0.8, 1 },
    -- no alpha, it is animated in the code
    scrollbar_color = { 1, 1, 1 },
    grabbed_scrollbar_color = { 1, 1, 0.8, 1 },

    button_background = i2c(0x31363bff),
    button_background_highlight = i2c(0x31363bff),
    button_border = i2c(0x838689ff),
    button_border_highlight = i2c(0x31363bff),
}

-- allows setting values in the table to overwrite them but restores default when set to nil
return setmetatable({}, { __index = theme })
