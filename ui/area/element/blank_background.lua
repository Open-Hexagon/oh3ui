local cursor = require("ui.cursor")
local blank = require("ui.draw_queue").by_cursor.blank
local stack_manager = require("ui.stack_manager")
local aeb = require("ui.area.aeb")
local draw_queue = require("ui.draw_queue")

local blank_background = {}

---starts a blank background
---@param n integer how many draw_queue slots to reserve
function blank_background.start(n)
    local res_id = draw_queue.allocate_reservation(n)
    cursor.start_area()

    aeb.push(res_id)
    aeb.push_frame_header("background")
    stack_manager.push_record()
end

---Finish the background. Any padding is treated as a cursor reshape.
---@param padl number
---@param padt number
---@param padr number
---@param padb number
---@return integer res_id reservation id (0 if background was empty)
---@return integer pid placement id (0 if background was empty)
---@nodiscard
function blank_background.finish(padl, padt, padr, padb)
    stack_manager.pop_record()
    aeb.pop_frame_header("background")
    local res_id = aeb.pop()

    if cursor.finish_area() then
        cursor.push()
        cursor.pad(padl, padt, padr, padb)
        local pid = blank()
        cursor.do_auto_reshape()
        return res_id, pid
    else
        draw_queue.close_reservation(res_id)
    end
    return 0, 0
end

return blank_background
