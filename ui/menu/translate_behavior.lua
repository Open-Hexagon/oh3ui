local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local theme = require("ui.theme")
local reserve = require("ui.reserve")
local stack_manager = require("ui.stack_manager")

return function()
    cursor.width = 10
    cursor.height = 10

    do
        cursor.x = 100
        cursor.y = 100

        primitive.rectangle(theme.red)

        cursor.apply_translation(100, 0)
        primitive.rectangle(theme.green)

        cursor.apply_translation(0, 100)
        primitive.rectangle(theme.cyan)

        cursor.remove_translation()
        cursor.remove_translation()
    end

    do
        cursor.x = 300
        cursor.y = 100

        stack_manager.push_record()

        primitive.rectangle(theme.red)

        cursor.apply_translation(100, 0)
        primitive.rectangle(theme.green)

        cursor.apply_translation(0, 100)
        primitive.rectangle(theme.cyan)

        stack_manager.pop_record()
    end
end
