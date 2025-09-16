local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local reserve = require("ui.reserve")
local stack_manager = require("ui.stack_manager")
local area_element = require("ui.element.area")
local area_type = area_element.kind.background

local background = {}

local function aeb_push(res_id)
    area_element.aeb_push(area_type)
    area_element.aeb_push(res_id)
end

local function aeb_pop()
    local res_id = area_element.aeb_pop()
    local a = area_element.aeb_pop()

    if a ~= area_type then
        error("background element was ended with wrong type")
    end

    return res_id
end

function background.start()
    local res_id = reserve.allocate(1)
    aeb_push(res_id)
    cursor.start_area()
    stack_manager.push_record()
end

---Finish the background
---@param pad number
---@param color table?
function background.finish(pad, color)
    stack_manager.pop_record()
    cursor.finish_area()
    local res_id = aeb_pop()
    cursor.outset(pad)
    reserve.take(res_id)
    primitive.rectangle(color)
end

return background
