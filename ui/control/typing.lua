local events = require("ui.events")
local utf8 = require("utf8")

local typing = {}

---string.sub but using utf8 chars instead of bytes for the indices
---@param str string
---@param i integer
---@param j integer
---@return string
local function utf8_sub(str, i, j)
    i = utf8.offset(str, i) or #str + 1
    if j > 0 then
        j = utf8.offset(str, j + 1) - 1
    end
    return str:sub(i, j)
end

local target_state
local text_pos
function typing.set_target(state)
    target_state = state
    if not target_state.text then
        target_state.text = ""
    end
end

function typing.evaluate()
    -- change text and text pos based on events
    local text = target_state.text
    for event in events.iterate("^[tk]e") do
        local name = event[1]
        if name == "textinput" then
            text = utf8_sub(text, 1, text_pos) .. event[2] .. utf8_sub(text, text_pos + 1, -1)
            text_pos = text_pos + 1
        elseif name == "keypressed" then
            local key = event[2]
            if key == "left" then
                text_pos = text_pos - 1
            elseif key == "right" then
                text_pos = text_pos + 1
            elseif key == "backspace" then
                text = utf8_sub(text, 1, math.max(text_pos - 1, 0)) .. utf8_sub(text, text_pos + 1, -1)
                text_pos = text_pos - 1
            elseif key == "delete" then
                text = utf8_sub(text, 1, text_pos) .. utf8_sub(text, text_pos + 2, -1)
            end
        elseif name == "textedited" then
            -- Apparently this is also a thing. I don't know what it does.
        end
    end
    target_state.text = text
end

return typing
