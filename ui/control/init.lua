local mouse_navigation = require("ui.control.mouse_navigation")
local keyboard_navigation = require("ui.control.keyboard_navigation")
local typing = require("ui.control.typing")
local shared = require("ui.control.shared")

--[[
TODO

if a navigation key is pressed, hide the mouse cursor

]]

---A module that oversees which control method is being used
local control = {}

function control.evaluate()
    mouse_navigation.evaluate()

    if typing.is_editing_any_text() then
        local goto_cell, tab_direction = typing.evaluate()

        -- do immediate keyboard navigation
        if goto_cell then
            keyboard_navigation.jump_to_cell(goto_cell)
            if tab_direction == typing.TAB_FORWARDS then
                keyboard_navigation.jump_forward()
            elseif tab_direction == typing.TAB_BACKWARDS then
                keyboard_navigation.jump_backwards()
            end
        end

        -- keyboard_navigation still needs to be cleaned up
        keyboard_navigation.evaluate_without_events()
    else
        local typing_target, typing_action = keyboard_navigation.evaluate()

        -- do immediate text editing
        if typing_target then
            typing.set_target(typing_target)
            if typing_action == "backspace" then
                if love.keyboard.isDown("lctrl", "rctrl") then
                    typing.truncate_target()
                else
                    typing.baskspace_target()
                end
            elseif typing_action == "delete" then
                -- delete is recognized but doesn't do anything since the cursor is always put at the end of the text
            else
                typing.insert_target(typing_action)
            end
        end
    end
end

return control
