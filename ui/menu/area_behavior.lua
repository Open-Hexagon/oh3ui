local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local theme = require("ui.theme")
local reserve = require("ui.reserve")
local stack_manager = require("ui.stack_manager")

return function()
    do
        cursor.width = 10
        cursor.height = 10

        local r = reserve.allocate(1)

        cursor.start_area()

        cursor.x = 100
        cursor.y = 100
        primitive.rectangle(theme.red)

        cursor.start_area()

        cursor.x = 150
        cursor.y = 150
        primitive.rectangle(theme.red)

        cursor.x = 300
        cursor.y = 300
        primitive.rectangle(theme.red)

        -- inner areas will update outer areas when finish_area is called
        cursor.finish_area()

        cursor.finish_area()

        cursor.outset(3)
        reserve.take(r)
        primitive.rectangle(theme.green)
    end

    do
        cursor.width = 10
        cursor.height = 10

        local r = reserve.allocate(1)

        cursor.start_area()

        cursor.x = 400
        cursor.y = 100
        primitive.rectangle(theme.red)

        cursor.x = 500
        cursor.y = 200
        -- areas that start and immediately end should not affect areas below
        cursor.start_area()
        cursor.finish_area()

        cursor.finish_area()

        cursor.outset(3)
        reserve.take(r)
        primitive.rectangle(theme.green)
    end

    do
        cursor.width = 10
        cursor.height = 10

        local r = reserve.allocate(1)

        cursor.start_area()
        cursor.x = 600
        cursor.y = 100
        primitive.rectangle(theme.red)

        cursor.x = 700
        cursor.y = 200
        primitive.rectangle(theme.red)

        stack_manager.push_record()

        cursor.start_area()
        cursor.x = 800
        cursor.y = 300
        primitive.rectangle(theme.red)

        -- an area that is prematurely terminated by a record pop will not update any outer areas
        stack_manager.pop_record()

        cursor.finish_area()

        cursor.outset(3)
        reserve.take(r)
        primitive.rectangle(theme.green)
    end
end
