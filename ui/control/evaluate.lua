local typing = require("ui.control.typing")
local control_backend = require("ui.control.backend")

return function()
    control_backend.mouse_navigation_evaluate()

    if typing.is_editing_any_text() then
        local goto_cell, tab_direction = control_backend.typing_evaluate()

        -- do immediate keyboard navigation
        if goto_cell then
            control_backend.last_used_control_method = "keyboard"

            control_backend.keyboard_navigation_jump_to_cell(goto_cell)
            if tab_direction == "tab_down" then
                control_backend.keyboard_navigation_tab_forward()
            elseif tab_direction == "tab_up" then
                control_backend.keyboard_navigation_tab_backwards()
            end
        end

        -- do keyboard_navigation clean up
        control_backend.keyboard_navigation_evaluate_without_events()
    else
        -- do typing cleanup
        control_backend.typing_evaluate_without_events()

        local typing_target, typing_action = control_backend.keyboard_navigation_evaluate()

        -- do immediate text editing
        if typing_target then
            control_backend.last_used_control_method = "typing"

            control_backend.typing_set_target(typing_target)
            if typing_action == "backspace" then
                if love.keyboard.isDown("lctrl", "rctrl") then
                    control_backend.typing_truncate(typing_target)
                else
                    control_backend.typing_backspace_character(typing_target)
                end
            elseif typing_action == "delete" then
                -- delete is recognized but doesn't do anything since the cursor is always put at the end of the text
            else
                ---if typing_target exists then so should typing_action
                ---@cast typing_action string
                control_backend.typing_insert_character(typing_target, typing_action)
            end
        end
    end

    control_backend.keyboard_navigation_reset()
    control_backend.mouse_navigation_reset()
end
