---Caches text objects so there's no need to repeatedly call love.graphics.print
---Also enables geting the width and height of text while respecting the wrap option before drawing
---(required for labels to support wrapping)

local ansi = require("ui.text.ansi")
local memoize = require("extlibs.memoize")

--[[
    * About text caching

    https://www.lua.org/gems/sample.pdf

    > All strings in Lua are internalized; this means that Lua keeps a single copy of
    > any string. Whenever a new string appears, Lua checks whether it already has a
    > copy of that string and, if so, reuses that copy. Internalization makes
    > operations like string comparison and table indexing very fast, but it slows
    > down string creation.

    So while doing this isn't necessarily great (since Lua has to check if it already
    has the string for each call), it doesn't result in a new object being allocated for
    every function call:
    foo("bar"); foo("bar"); foo("bar")
    
    This however, is not very good since each call allocates a new table for each call,
    defeating the purpose of our cache:
    foo({}); foo({}); foo({})

    Table elements are also not part of the hash so if the contents of a table change,
    the cache will have no idea about it and won't update. So while this fixes the
    reallocation issue, editing the table won't update the corresponding text.
    a = {}; foo(a); foo(a); foo(a)
]]

-- TODO This doesn't reuse old text batches like it used to. Maybe reimplement later.

local get_text_object_inner = memoize(function(font, text, wraplimit, align)
    -- check if the text has color information
    local coloredtext = nil
    if string.sub(text, 1, 1) == "\x1b" then
        coloredtext = ansi.string_to_colored_text(text)
    end

    local text_batch = love.graphics.newTextBatch(font)
    text_batch:setf(coloredtext or text, wraplimit, align)

    return text_batch
end)

---Get a text object using font, text, wraplimit and align mode.
---If text is a string, it will be cached; use this for regular text.
---If text is a colored string (starts with '\x1b'), it will be cached; use this for colored text that doesn't change much.
---Does not accept colored text tables. These tables cannot be cached easily. It's recommended to use native love2d
---functions for colored text that changes often.
---@param font love.Font
---@param text string
---@param wraplimit number
---@param align love.AlignMode
---@return love.Text
---@nodiscard
local function get_text_object(font, text, wraplimit, align)
    if type(text) == "table" then
        error("sorry, colored text tables are not accepted")
    end

    return get_text_object_inner(font, text, wraplimit, align)
end

return get_text_object
