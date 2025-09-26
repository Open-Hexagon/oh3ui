local cursor = require("ui.cursor")
local area_element = require("ui.area")
local stack_manager = require("ui.stack_manager")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local selection_outline_add_to_queue = require("ui.decorator.selection_outline").add_to_queue
local follow = require("ui.effect").follow
local reserve = require("ui.reserve")
local volatile_data = require("ui.shared_data").volatile
local view_request = require("ui.area.view_request")

local collapse = {}

--TODO relocate the keyboard selection if collapse is closed with the selection inside
--TODO keyboard navigation can notify a collapse state to auto open

---@param state table
---@param anchor_pos "topleft"|"bottomright" The corner of the collapse area that won't move
---@param clipping_side "left"|"top"|"right"|"bottom" The collapse area side that cuts off the contents
---@param auto_open boolean? collapse will open automatically when keyboard selection enters
---@param sensor_id integer? optional sensor id
---@param cell_id integer? optional cell id
function collapse.start(state, anchor_pos, clipping_side, auto_open, sensor_id, cell_id)
    state.value = state.value or 0
    state._max_size = state._max_size or 0

    local res_id = reserve.allocate(1)

    cursor.start_area()

    -- These translations lag behind by one frame, but since collapses move so fast it's normally barely noticeable.
    if anchor_pos == "topleft" then
        if clipping_side == "top" then
            cursor.apply_translation(0, state.value - state._max_size)
        elseif clipping_side == "left" then
            cursor.apply_translation(state.value - state._max_size, 0)
        else
            cursor.apply_translation(0, 0)
        end
    else
        if clipping_side == "bottom" then
            cursor.apply_translation(0, state._max_size - state.value)
        elseif clipping_side == "right" then
            cursor.apply_translation(state._max_size - state.value, 0)
        else
            cursor.apply_translation(0, 0)
        end
    end

    area_element.aeb_push(cursor.anchor_y) -- anchors should be preserved
    area_element.aeb_push(cursor.anchor_x)
    area_element.aeb_push(clipping_side)
    area_element.aeb_push(anchor_pos)
    area_element.aeb_push(mnav.get_clicked(sensor_id) == mb.left or knav.get_action(cell_id) == kba.activate)
    area_element.aeb_push(res_id)
    area_element.aeb_push(state)
    area_element.aeb_push(false)
    area_element.aeb_push(view_request.collapse_top_index) -- aeb_index of the next (up) state
    view_request.collapse_top_index = volatile_data.aeb_index -- put the new view request top index

    area_element.aeb_push_frame_header("collapse")

    stack_manager.push_record()
end

function collapse.finish()
    stack_manager.pop_record()

    local add_selection_outline = area_element.aeb_pop_frame_header("collapse")

    view_request.collapse_top_index = area_element.aeb_pop() -- revert the view request top index
    local force_open = area_element.aeb_pop()
    local state = area_element.aeb_pop()
    local res_id = area_element.aeb_pop()
    local left_clicked = area_element.aeb_pop()

    local anchor_pos
    if area_element.aeb_pop() == "topleft" then
        anchor_pos = 0
    else
        anchor_pos = 1
    end

    ---@type "left"|"top"|"right"|"bottom"
    local clipping_side = area_element.aeb_pop()
    local ax = area_element.aeb_pop() -- anchors should be preserved
    local ay = area_element.aeb_pop()

    cursor.remove_translation()
    cursor.finish_area(true)

    local max_size
    local dimension
    if clipping_side == "left" or clipping_side == "right" then
        max_size = cursor.width
        dimension = "width"
    elseif clipping_side == "top" or clipping_side == "bottom" then
        max_size = cursor.height
        dimension = "height"
    else
        error("bad clipping side")
    end

    state._max_size = max_size

    if force_open then
        state.on = true
    else
        if left_clicked then
            state.on = not state.on
        end
    end

    if state.on then
        state.value = follow(state.value, max_size, 1800)
    else
        state.value = follow(state.value, 0, 1800)
    end

    cursor.change_anchor(anchor_pos)
    cursor[dimension] = state.value
    reserve.take(res_id)
    mask.push()
    mask.pop()

    if add_selection_outline then
        selection_outline_add_to_queue()
    end

    cursor.change_anchor(ax, ay) -- revert anchors
end

return collapse
