local mouse_navigation = require("ui.control.mouse_navigation")
local keyboard_navigation = require("ui.control.keyboard_navigation")
local typing = require("ui.control.typing")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local control_method = shared_data.enums.control_method

local typing_tab_up = typing.stop_methods.tab_up
local typing_tab_down = typing.stop_methods.tab_down

---A module that oversees which control method is being used
local control = {}

function control.evaluate()
    mouse_navigation.evaluate()

    if typing.is_editing_any_text() then
        local goto_cell, tab_direction = typing.evaluate()

        -- do immediate keyboard navigation
        if goto_cell then
            control_data.last_used_control_method = control_method.keyboard

            keyboard_navigation.jump_to_cell(goto_cell)
            if tab_direction == typing_tab_down then
                keyboard_navigation.tab_forward()
            elseif tab_direction == typing_tab_up then
                keyboard_navigation.tab_backwards()
            end
        end

        -- do keyboard_navigation clean up
        keyboard_navigation.evaluate_without_events()
    else
        -- do typing cleanup
        typing.evaluate_without_events()

        local typing_target, typing_action = keyboard_navigation.evaluate()

        -- do immediate text editing
        if typing_target then
            control_data.last_used_control_method = control_method.typing

            typing.set_target(typing_target)
            if typing_action == "backspace" then
                if love.keyboard.isDown("lctrl", "rctrl") then
                    typing.truncate(typing_target)
                else
                    typing.backspace_character(typing_target)
                end
            elseif typing_action == "delete" then
                -- delete is recognized but doesn't do anything since the cursor is always put at the end of the text
            else
                ---if typing_target exists then so should typing_action
                ---@cast typing_action string
                typing.insert_character(typing_target, typing_action)
            end
        end
    end

    keyboard_navigation.reset()
    mouse_navigation.reset()
end

return control
