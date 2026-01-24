local cursor = require("ui.cursor")
local rectangle = require("ui.draw_queue").by_cursor.rectangle
local stack_manager = require("ui.stack_manager")
local aeb = require("ui.area.aeb")
local draw_queue = require("ui.draw_queue")

local background = {}

function background.start()
    local res_id = draw_queue.allocate_reservation(1)
    cursor.start_area()

    aeb.push(res_id)
    aeb.push_frame_header("background")
    stack_manager.push_record()
end

---Finish the background
---@param pad number
---@param color table?
function background.finish(pad, color)
    stack_manager.pop_record()
    aeb.pop_frame_header("background")
    local res_id = aeb.pop()

    if cursor.finish_area() then
        cursor.outset(pad)
        draw_queue.next_takes_reservation(res_id)
        rectangle(color)
    else
        draw_queue.next_takes_reservation(res_id)
        draw_queue.nop()
    end
end

return background
