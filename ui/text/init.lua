---For stuff related to text, but not drawing of text.
---No text scaling of any kind is done by these functions.
---What you put in is what you get out.

local json = require("extlibs.json.json")
local theme = require("ui.theme")

local text = {
    ansi = require("ui.text.ansi"),

    -- TODO These functions all use similar caches for memoization. Maybe generalize later.
    search = require("ui.text.search"),
    get_wrapped_text = require("ui.text.wrapping"),
    get_text_object = require("ui.text.cache"),
}

---Cache of fonts based on file used and size
local font_cache = {}

---Gets a font object.
---@param size number
---@param font_path string? override theme text font
---@return love.Font
---@nodiscard
function text.get_font(size, font_path)
    font_path = font_path or theme.font_path
    if not font_path then
        error("theme.font_path is not set!")
    end
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
---@param icon_font_path string? override theme icon font
---@return string
---@nodiscard
function text.get_icon_string(icon_name, icon_font_path)
    icon_font_path = icon_font_path or theme.icon_font_path
    if not icon_font_path then
        error("theme.icon_font_path is not set!")
    end
    -- try to find the table in the cache
    local icon_table = icon_font_table_cache[icon_font_path]
    if not icon_table then
        -- get the corresponding json file path
        local json_file = string.gsub(icon_font_path, "(.*)%..+", "%1.json")
        if not love.filesystem.exists(json_file) then
            error(string.format("Could not find json file for icon font %s", icon_font_path), 2)
        end

        icon_table = json.decode(love.filesystem.read(json_file))
        for name, value in pairs(icon_table) do
            icon_table[name] = love.data.decode("string", "hex", value)
        end

        icon_font_table_cache[icon_font_path] = icon_table
    end

    local str = icon_table[icon_name]
    if not str then
        error(string.format("Could not find `%s` in `%s` icon table", icon_name, icon_font_path), 2)
    end

    return str
end

---Gets a new string with any icon sequences replaced with their real utf-8 representations.
---Icon sequences are formatted as "\x1c&icon-name;" where "icon-name" is the icons name in the icon font's corresponding json file
---@param format_str string
---@param icon_font_path string? override theme icon font
---@return string
---@return integer
function text.replace_icon_sequences(format_str, icon_font_path)
    return format_str:gsub("\x1c&([^;]+);", function(icon_name)
        return text.get_icon_string(icon_name, icon_font_path)
    end)
end

return text
