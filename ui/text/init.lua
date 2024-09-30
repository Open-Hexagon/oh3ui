---For stuff related to text, but not drawing of text.

local text_cache = require("ui.text.cache")

local text = {}

---Get size of text
---@param str string
---@param font love.Font
---@param wraplimit number?
---@param align love.AlignMode?
---@return number, number
function text.get_size(str, font, wraplimit, align)
    local text_object = text_cache.get(font, str, wraplimit or math.huge, align or "left")
    -- scale the font size back since font point size was scaled by ui.scaling
    return love.graphics.inverseTransformPoint(text_object:getDimensions())
end

return text
