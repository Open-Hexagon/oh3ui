local text_cache = {}

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
            text_object_usage[text] = nil
            text_object_contents[text] = nil
            text_object_wraplimit[text] = nil
            text_object_align[text] = nil
            table.remove(text_object_array, i)
            if #unused_text_objects < 10 then
                -- cache for later use with different text (decreases memory allocation)
                -- but only if there are not a lot of unused objects yet
                unused_text_objects[#unused_text_objects + 1] = text
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
local update_interval = 0.5 -- seconds

---get a text object with the correct font, text, wraplimit and align mode
---@param font love.Font
---@param text string
---@param wraplimit number
---@param align love.AlignMode
---@return love.Text
function text_cache.get(font, text, wraplimit, align)
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
        if cached_object then
            -- set unused object to correct font
            cached_object:setFont(font)
            unused_text_objects[#unused_text_objects] = nil
        else
            -- no unused objects, create a new one
            cached_object = love.graphics.newTextBatch(font)
        end
        -- set correct text, wraplimit and align mode
        cached_object:setf(text, wraplimit, align)
        -- add cache entries
        text_objects[font] = text_objects[font] or {}
        text_objects[font][text] = text_objects[font][text] or {}
        text_objects[font][text][wraplimit] = text_objects[font][text][wraplimit] or {}
        text_objects[font][text][wraplimit][align] = cached_object
        text_object_array[#text_object_array + 1] = cached_object
        text_object_contents[cached_object] = text
        text_object_wraplimit[cached_object] = wraplimit
        text_object_align[cached_object] = align
    end
    local text_object = text_objects[font][text][wraplimit][align]
    -- update usage statistics
    text_object_usage[text_object] = (text_object_usage[text_object] or 0) + 1
    return text_object
end

return text_cache
