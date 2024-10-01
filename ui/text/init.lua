---For stuff related to text, but not drawing of text.

local json = require("extlibs.json.json")
local text_cache = require("ui.text.cache")

local text = {}

---Default font
text.font = "assets/OpenSquare.ttf"
---Default font size
text.font_size = 32
---Default text alignment
text.align = "left"
---If true, the cursor width will be used to wrap text.
text.wrap = false
---Default icon font
text.icon_font = "assets/bootstrap-icons.ttf"

---Cache of fonts based on file used and size
local font_cache = {}

---Get the currently used font object.
---Font size is always scaled by the ui.scaling so that it can be later drawn at full resolution.
---@param size number? override default font size
---@param font_path string? override text.font
---@return love.Font
function text.get_font(size, font_path)
    font_path = font_path or text.font
    -- increase the size of the font by the ui scaling
    size = (size or text.font_size) * math.floor(require("ui").scale * 100) / 100
    font_cache[font_path] = font_cache[font_path] or {}
    local font = font_cache[font_path][size]
    if not font then
        if not love.filesystem.exists(font_path) then
            error(string.format("Could not find font `%s`", font_path))
        end
        font = love.graphics.newFont(font_path, size)
        font:setFilter("nearest", "nearest")
        font_cache[font_path][size] = font
    end
    return font
end

---A cache of tables, keyed with icon font paths.
---Each cached table has icon names as keys and representative strings as values for an icon font.
local icon_font_table_cache = {}

---@param icon_name string
---@param font_path string
---@return string
function text.get_icon_string(icon_name, font_path)
    -- try to find the table in the cache
    local icon_table = icon_font_table_cache[font_path]
    if not icon_table then
        -- get the corresponding json file path
        local json_file = string.gsub(font_path, "(.*)%..+", "%1.json")
        if not love.filesystem.exists(json_file) then
            error(string.format("Could not find json file for icon font %s", font_path))
        end

        icon_table = json.decode(love.filesystem.read(json_file))
        for name, value in pairs(icon_table) do
            icon_table[name] = love.data.decode("string", "hex", value)
        end

        icon_font_table_cache[json_file] = icon_table
    end

    local str = icon_table[icon_name]
    if not str then
        error(string.format("Could not find `%s` in `%s` icon table", icon_name, font_path))
    end

    return str
end

---Get size of text
---@param str string
---@param font love.Font
---@param wraplimit number?
---@param align love.AlignMode?
---@return number, number
function text.get_size(str, font, wraplimit, align)
    local text_object = text_cache.get(font, str, wraplimit or math.huge, align or "left")
    -- scale the font size back since font size was scaled by ui.scaling
    return love.graphics.inverseTransformPoint(text_object:getDimensions())
end

return text
