local cursor = require("ui.cursor")
local primitive = require("ui.primitive")
local area_element = require("ui.element.area")
local stack_manager = require("ui.stack_manager")
local mask = require("ui.mask")
local theme = require("ui.theme")
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local selection_outline_add_to_queue = require("ui.element.decorator.selection_outline").add_to_queue
local control_data = require("ui.shared_data").control
local follow = require("ui.effect").follow
local reserve = require("ui.reserve")
local volatile_data = require("ui.shared_data").volatile

local header_height = 20
local minimum_width = 100
local speed = 10

local collapse = {}
local depth = 0
local top_index = nil

--[[

scroll start

    * set_location    

* add_to_queue
scroll finish
    

collapse start
    * set_location
    collapse start
    
        *

    collapse finish

    *

collapse finish
* add_to_queue



]]

--TODO relocate the keyboard selection if collapse is closed with the selection inside
--TODO keyboard navigation can notify a collapse state to auto open
--TODO have a no-header mode
--TODO have an auto-fit mode
--TODO be able to collapse in any direction

---@param state table
---@param direction "opens_down"|"opens_up"|"opens_left"|"opens_right"
---@param sensor_id integer?
---@param cell_id integer?
function collapse.start(state, direction, sensor_id, cell_id)
    cursor.push()

    local res_id = reserve.allocate(1)
    cursor.start_area()

    area_element.aeb_push(direction)
    area_element.aeb_push(mnav.get_clicked(sensor_id) == mb.left or knav.get_action(cell_id) == kba.activate)
    area_element.aeb_push(res_id)
    area_element.aeb_push(state)

    area_element.aeb_push_frame_header("collapse")

    stack_manager.push_record()
end

function collapse.finish(padding)
    stack_manager.pop_record()

    local add_selection_outline = area_element.aeb_pop_frame_header("collapse")

    local state = area_element.aeb_pop()
    local res_id = area_element.aeb_pop()
    local left_clicked = area_element.aeb_pop()
    ---@type "opens_down"|"opens_up"|"opens_left"|"opens_right"
    local direction = area_element.aeb_pop()

    cursor.finish_area(true)

    local anchor_pos
    local max_size
    local dimension
    if direction == "opens_down" then
        anchor_pos = 0
        max_size = cursor.height
        dimension = "height"
    elseif direction == "opens_up" then
        anchor_pos = 1
        max_size = cursor.height
        dimension = "height"
    elseif direction == "opens_left" then
        anchor_pos = 1
        max_size = cursor.width
        dimension = "width"
    elseif direction == "opens_right" then
        anchor_pos = 0
        max_size = cursor.width
        dimension = "width"
    end

    cursor.change_anchor(anchor_pos)
    state._collapse_size = state._collapse_size or 0
    if left_clicked then
        state.on = not state.on
        if state.on then
            state._collapse_speed = (max_size - state._collapse_size) * speed
        else
            state._collapse_speed = state._collapse_size * speed
        end
    end
    if state.on then
        state._collapse_size = follow(state._collapse_size, max_size, 2500)
    else
        state._collapse_size = follow(state._collapse_size, 0, 2500)
    end

    cursor[dimension] = state._collapse_size
    reserve.take(res_id)
    mask.push()
    mask.pop()
    selection_outline_add_to_queue()

    cursor.do_auto_reshape(true)
end

return collapse
