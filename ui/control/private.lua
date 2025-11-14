local utf8_sub = require("ui.text.utf8_sub")

---Functions that shouldn't be part of the user facing api
local private = {
    ---@type fun():integer?,typing_stop_methods
    typing_evaluate = nil,

    ---@type fun()
    typing_evaluate_without_events = nil,

    ---@type fun(table)
    typing_set_target = nil,

    ---@type fun()
    mouse_navigation_evaluate = nil,

    ---@type fun()
    mouse_navigation_reset = nil,

    ---@type fun():table?,string?
    keyboard_navigation_evaluate = nil,

    ---@type fun()
    keyboard_navigation_evaluate_without_events = nil,

    ---@type fun()
    keyboard_navigation_reset = nil,

    ---@type fun()
    keyboard_navigation_finish_layer_transition = nil,

    ---@type fun(integer,table,boolean?)
    keyboard_navigation_configure_cell_as_text_input = nil,
}

---Inserts a character into the state
---@param state table
---@param char string
function private.typing_insert_character(state, char)
    state.text = utf8_sub(state.text, 1, state._text_entry_char_position)
        .. char
        .. utf8_sub(state.text, state._text_entry_char_position + 1, -1)
    state._text_entry_char_position = state._text_entry_char_position + 1
end

---Deletes all text in the state
---@param state table
function private.typing_truncate(state)
    state.text = ""
    state._text_entry_char_position = 0
end

---Uses backspace on the state
---@param state table
function private.typing_backspace_character(state)
    if state._text_entry_char_position > 0 then
        state.text = utf8_sub(state.text, 1, state._text_entry_char_position - 1)
            .. utf8_sub(state.text, state._text_entry_char_position + 1, -1)
        state._text_entry_char_position = state._text_entry_char_position - 1

        state._text_entry_text_offset = 0
    end
end

return private
