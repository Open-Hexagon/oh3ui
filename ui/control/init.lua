local mouse_navigation = require("ui.control.mouse_navigation")
local keyboard_navigation = require("ui.control.keyboard_navigation")
local typing = require("ui.control.typing")

--[[
TODO

if a navigation key is pressed, hide the mouse cursor

keyboard navigation hotkeys

if the default keyboard cell is a text entry pressing any key will immediately activate it without having to navigate to it

]]

---A module that oversees which control method is being used
local control = {}

function control.evaluate()
    mouse_navigation.evaluate()
    if typing.is_editing_text() then
        local goto_keyboard_selection, tabbed_out = typing.evaluate()
        if goto_keyboard_selection then
            keyboard_navigation.jump_to_cell(goto_keyboard_selection)
            if tabbed_out then
                keyboard_navigation.jump_forward()
            end
        end
        keyboard_navigation.evaluate_without_events()
    else
        local set_typing_target, text = keyboard_navigation.evaluate()
        if set_typing_target then
            typing.set_target(set_typing_target, text)
        end
    end
end

return control
