local keyboard_navigation = require("ui.control.keyboard_navigation")
local typing = require("ui.control.typing")

local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local private = require("ui.control.private")

return function()
    private.mouse_navigation_evaluate()

    if typing.is_editing_any_text() then
        local goto_cell, tab_direction = private.typing_evaluate()

        -- do immediate keyboard navigation
        if goto_cell then
            control_data.last_used_control_method = "keyboard"

            keyboard_navigation.jump_to_cell(goto_cell)
            if tab_direction == "tab_down" then
                keyboard_navigation.tab_forward()
            elseif tab_direction == "tab_up" then
                keyboard_navigation.tab_backwards()
            end
        end

        -- do keyboard_navigation clean up
        private.keyboard_navigation_evaluate_without_events()
    else
        -- do typing cleanup
        private.typing_evaluate_without_events()

        local typing_target, typing_action = private.keyboard_navigation_evaluate()

        -- do immediate text editing
        if typing_target then
            control_data.last_used_control_method = "typing"

            private.typing_set_target(typing_target)
            if typing_action == "backspace" then
                if love.keyboard.isDown("lctrl", "rctrl") then
                    private.typing_truncate(typing_target)
                else
                    private.typing_backspace_character(typing_target)
                end
            elseif typing_action == "delete" then
                -- delete is recognized but doesn't do anything since the cursor is always put at the end of the text
            else
                ---if typing_target exists then so should typing_action
                ---@cast typing_action string
                private.typing_insert_character(typing_target, typing_action)
            end
        end
    end

    private.keyboard_navigation_reset()
    private.mouse_navigation_reset()
end
