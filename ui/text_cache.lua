local text_cache = {}

local text_objects = {}
local text_object_usage = {}
local text_object_contents = {}
local unused_text_objects = {}

---clears objects that haven't been used since the last update
local function update()
    for i = #text_object_contents, 1, -1 do
        local text = text_object_contents[i]
        if text_object_usage[text] == 0 then
            -- text was not used
            if #unused_text_objects < 10 then
                -- cache for later use with different text (decreases memory allocation)
                -- but only if there are not a lot of unused objects yet
                unused_text_objects[#unused_text_objects + 1] = text_objects[text]
            else
                -- otherwise delete it immediately
                text_objects[text]:release()
            end
            -- remove cache entries
            text_objects[text] = nil
            text_object_usage[text] = nil
            table.remove(text_object_contents, i)
        else
            -- text was used, start counting at 0 again until next time
            text_object_usage[text] = 0
        end
    end
end

local last_update = love.timer.getTime()
local update_interval = 10  -- seconds

---get a text object with the correct text and font
---@param text string
---@param font love.Font
---@return love.Text
function text_cache.get(text, font)
    -- update cache in case the update interval has passed
    local time = love.timer.getTime()
    if time - last_update > update_interval then
        last_update = time
        update()
    end
    -- check if text object is cached
    if text_objects[text] == nil then
        -- it is not cached, check if an unused one can be used
        local cached_object = unused_text_objects[#unused_text_objects]
        if cached_object then
            -- set unused object to correct text and font
            cached_object:set(text)
            cached_object:setFont(font)
            text_objects[text] = cached_object
            unused_text_objects[#unused_text_objects] = nil
        else
            -- no unused objects, create a new one
            text_objects[text] = love.graphics.newTextBatch(font, text)
        end
        -- add cache entry
        text_object_contents[#text_object_contents + 1] = text
    end
    -- update usage statistics
    text_object_usage[text] = (text_object_usage[text] or 0) + 1
    return text_objects[text]
end

return text_cache
