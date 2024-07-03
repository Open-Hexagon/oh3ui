local state = require("ui.state")
local events = require("ui.events")
local draw_queue = require("ui.draw_queue")
local scroll_interaction = require("ui.interaction.scroll")
local utf8 = require("utf8")

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

local text_interaction = {}
text_interaction.is_interacting_with_text = false

---reset in entry state
function text_interaction.reset()
    text_interaction.is_interacting_with_text = false
end

---update text input interaction
---@param entry_state table
function text_interaction.update(entry_state)
    entry_state.text = entry_state.text or ""
    if entry_state.selected then
        text_interaction.is_interacting_with_text = true
        entry_state.text_pos = entry_state.text_pos or 0
        local text = entry_state.text
        local text_pos = entry_state.text_pos

        -- change text and text pos based on events
        for event in events.iterate() do
            if event[1] == "textinput" then
                text = utf8_sub(text, 1, text_pos) .. event[2] .. utf8_sub(text, text_pos + 1, -1)
                text_pos = text_pos + 1
            elseif event[1] == "keypressed" then
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
            end
        end

        -- update text pos, cursor pos and scroll position
        entry_state.text = text
        if entry_state.text_pos ~= text_pos then
            -- text pos differs, limit to text bounds
            if text_pos > utf8.len(text) then
                text_pos = utf8.len(text)
            elseif text_pos < 0 then
                text_pos = 0
            end
            if entry_state.text_pos ~= text_pos then
                -- text pos still differs
                -- calculate pixel pos
                entry_state.cursor_pos = draw_queue.get_text_size(utf8_sub(text, 1, text_pos), state.get_font(), state.text_wraplimit, state.text_align)
                -- scroll cursor into view
                local scroll_padding = 10
                local min_scroll_pos = entry_state.cursor_pos - state.width + scroll_padding
                local max_scroll_pos = entry_state.cursor_pos - scroll_padding
                if entry_state.scroll_state.position < min_scroll_pos then
                    scroll_interaction.go_to(min_scroll_pos, 0.1, "linear")
                elseif entry_state.scroll_state.position > max_scroll_pos then
                    scroll_interaction.go_to(max_scroll_pos, 0.1, "linear")
                end
                -- set text pos
                entry_state.text_pos = text_pos
            end
        end
    end
end

return text_interaction
