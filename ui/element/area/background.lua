local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local reserve = require("ui.reserve")
local volatile_data = require("ui.shared_data").volatile
local aeb_stack = volatile_data.aeb_stack
local area_type = require("ui.element.area").kind.background
local stack_manager = require("ui.stack_manager")

local background = {}

local function aeb_push(res_id)
    local index = volatile_data.aeb_index + 1
    aeb_stack[index] = aeb_stack[index] or {}
    local slot = aeb_stack[index]

    slot[1] = area_type
    slot[2] = res_id

    volatile_data.aeb_index = index
end

local function aeb_pop()
    local index = volatile_data.aeb_index
    local slot = aeb_stack[index]

    if slot[1] ~= area_type then
        error("area element was ended with wrong type")
    end

    volatile_data.aeb_index = index - 1

    return slot[2]
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
