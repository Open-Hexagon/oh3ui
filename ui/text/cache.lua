---Caches text objects so there's no need to repeatedly call love.graphics.print
---Also enables geting the width and height of text while respecting the wrap option before drawing
---(required for labels to support wrapping)

local ansi = require("ui.text.ansi")

local text_objects = {}
local text_object_usage = {}
local text_object_array = {}
local text_object_contents = {}
local text_object_wraplimit = {}
local text_object_align = {}
local unused_text_objects = {}

---clears objects that haven't been used since the last update
local function update()
    for i = #text_object_array, 1, -1 do
        local text = text_object_array[i]
        local font = text:getFont()
        local contents = text_object_contents[text]
        local wraplimit = text_object_wraplimit[text]
        local align = text_object_align[text]
        if text_object_usage[text] == 0 then
            -- text was not used
            -- remove cache entries
            text_objects[font][contents][wraplimit][align] = nil

            -- delete tables if they're empty
            if next(text_objects[font][contents][wraplimit]) == nil then
                text_objects[font][contents][wraplimit] = nil
                if next(text_objects[font][contents]) == nil then
                    text_objects[font][contents] = nil
                    if next(text_objects[font]) == nil then
                        text_objects[font] = nil
                    end
                end
            end

            text_object_usage[text] = nil
            text_object_contents[text] = nil
            text_object_wraplimit[text] = nil
            text_object_align[text] = nil
            table.remove(text_object_array, i)
            if #unused_text_objects < 10 then
                -- cache for later use with different text (decreases memory allocation)
                -- but only if there are not a lot of unused objects yet
                table.insert(unused_text_objects, text)
            else
                -- otherwise delete it immediately
                text:release()
            end
        else
            -- text was used, start counting at 0 again until next time
            text_object_usage[text] = 0
        end
    end
end

local last_update = love.timer.getTime()
local update_interval = 1 -- seconds

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
    -- update cache in case the update interval has passed
    local time = love.timer.getTime()
    if time - last_update > update_interval then
        last_update = time
        update()
    end
    -- check if text object is cached
    if
        text_objects[font] == nil
        or text_objects[font][text] == nil
        or text_objects[font][text][wraplimit] == nil
        or text_objects[font][text][wraplimit][align] == nil
    then
        -- it is not cached, check if an unused one can be used
        local cached_object = unused_text_objects[#unused_text_objects]
        -- check if the text has color information
        local coloredtext = nil
        if string.sub(text, 1, 1) == "\x1b" then
            coloredtext = ansi.string_to_colored_text(text)
        end
        if cached_object then
            -- set unused object to correct font
            cached_object:setFont(font)
            table.remove(unused_text_objects)
        else
            -- no unused objects, create a new one
            cached_object = love.graphics.newTextBatch(font)
        end
        -- set correct text, wraplimit and align mode
        cached_object:setf(coloredtext or text, wraplimit, align)
        -- add cache entries
        text_objects[font] = text_objects[font] or {}
        text_objects[font][text] = text_objects[font][text] or {}
        text_objects[font][text][wraplimit] = text_objects[font][text][wraplimit] or {}
        text_objects[font][text][wraplimit][align] = cached_object
        table.insert(text_object_array, cached_object)
        text_object_contents[cached_object] = text
        text_object_wraplimit[cached_object] = wraplimit
        text_object_align[cached_object] = align
    end

    local text_object = text_objects[font][text][wraplimit][align]
    -- update usage statistics
    text_object_usage[text_object] = (text_object_usage[text_object] or 0) + 1
    return text_object
end

return get_text_object
