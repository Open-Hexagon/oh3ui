-- An example menu to figure out what the hell I'm doing
-- Start from first principles

local cursor = require("ui.cursor")
local output = require("ui.cursor.output")
local rectangle = require("ui.element.rectangle")
local background = require("ui.area.background")
local theme = require("ui.theme")

return function()
    -- nothing here yet

    -- input.x = 10
    -- input.y = 10

    -- input.width = 100
    -- input.height = 200

    -- rectangle()

    -- if output.pressed then

    -- end

    -- if output.released then

    -- end

    cursor.anchor_x = 0
    cursor.anchor_y = 0
    cursor.x = 40
    cursor.y = 40
    cursor.width = 20
    cursor.height = 20

    for x1, y1 in cursor.grid(3, 3, 80) do
        background.start()
        for x2, y2 in cursor.grid(3, 3, 10) do
            rectangle()
            if output.mouse.enter then
                print("enter", x1, y1, x2, y2)
            end
            -- if output.mouse.hovering then
            --     print("hovering", x1, y1, x2, y2)
            -- end
            if output.mouse.exit then
                print("exit", x1, y1, x2, y2)
            end

            for _, v in pairs({ "left", "right", "middle", "back", "forward" }) do
            -- for v = 1, 5 do
                if output.mouse[v].down then
                    print(v .. " down", output.mouse[v].times)
                end
                -- if output.mouse[v].pressed then
                --     print(v .. " pressed", output.mouse[v].times)
                -- end
                if output.mouse[v].up then
                    print(v .. " up", output.mouse[v].times)
                end
            end

            cursor.inset(0.5)
            theme.rectangle_color = { 1, 1, 1, 1 }
            rectangle("line")
            theme.rectangle_color = nil
        end
        theme.rectangle_color = { 1, 0, 0, 1 }
        background.finish()
        theme.rectangle_color = nil
    end

    -- draw_queue.push_scissor(0, 0, 60, 60)
    -- draw_queue.rectangle("fill", 0, 0, 100, 100, { 1, 0, 0, 1 })
    -- draw_queue.push_scissor(30, 30, 90, 90)
    -- draw_queue.rectangle("fill", 0, 0, 100, 100, { 0, 1, 0, 1 })

    -- draw_queue.pop_scissor()
    -- draw_queue.pop_scissor()

    -- draw_queue.reserve()
    -- draw_queue.next_takes_last_reservation()
    -- draw_queue.rectangle("fill", 30, 30, 120, 120, {0, 0, 1, 1})
end
