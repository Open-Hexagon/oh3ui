-- An example menu to figure out what the hell I'm doing
-- Start from first principles

local input = require("ui.io.input")
local output = require("ui.io.output")
local anchor = require("ui.io.anchor")
local draw_queue = require("ui.draw_queue")


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

    draw_queue.push_scissor(0, 0, 60, 60)
    draw_queue.rectangle("fill", 0, 0, 100, 100, {1, 0, 0, 1})
    draw_queue.push_scissor(30, 30, 90, 90)
    draw_queue.rectangle("fill", 0, 0, 100, 100, {0, 1, 0, 1})

    draw_queue.pop_scissor()
    draw_queue.pop_scissor()


    -- draw_queue.reserve()
    -- draw_queue.next_takes_last_reservation()
    -- draw_queue.rectangle("fill", 30, 30, 120, 120, {0, 0, 1, 1})


end