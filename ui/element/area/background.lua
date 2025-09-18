local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local reserve = require("ui.reserve")
local stack_manager = require("ui.stack_manager")
local area_element = require("ui.element.area")

local background = {}

function background.start()
    local res_id = reserve.allocate(1)
    cursor.start_area()

    area_element.aeb_push(res_id)
    area_element.aeb_push("background")
    stack_manager.push_record()
end

---Finish the background
---@param pad number
---@param color table?
function background.finish(pad, color)
    stack_manager.pop_record()
    local a = area_element.aeb_pop()

    if a ~= "background" then
        error("background element was ended with wrong type")
    end

    local res_id = area_element.aeb_pop()

    cursor.finish_area()
    cursor.outset(pad)
    reserve.take(res_id)
    primitive.rectangle(color)
end

return background
