local cursor = require("ui.cursor")
local area_element = require("ui.area")
local stack_manager = require("ui.stack_manager")
local mask = require("ui.mask")
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local selection_outline = require("ui.decorator.selection_outline")
local follow = require("ui.effect").follow
local reserve = require("ui.reserve")
local volatile_data = require("ui.shared_data").volatile
local view_request = require("ui.area.view_request")
local decorator = require("ui.decorator")

local selection_outline_cutoff = decorator.selection_outline_outset + decorator.selection_outline_line_width * 0.5
-- this is an arbitrary value, it only needs to be bigger than selection_outline_cutoff
local selection_outline_cutoff3 = selection_outline_cutoff * 3

local collapse = {}

local speed = 100 --1800

---@param state table
---@param anchor_pos "topleft"|"bottomright" The corner of the collapse area that won't move
---@param clipping_side "left"|"top"|"right"|"bottom" The collapse area side that cuts off the contents
---@param no_auto_open boolean? collapse won't auto open; establishes a keyboard nav keepout zone
---@param sensor_id integer? optional sensor id
---@param cell_id integer? optional cell id
function collapse.start(state, anchor_pos, clipping_side, no_auto_open, sensor_id, cell_id)
    local res_id = reserve.allocate(1)

    cursor.start_area()

    -- guess the translation
    local tid = cursor.push_translation(state._last_dx or 0, state._last_dy or 0)

    area_element.aeb_push(tid)
    area_element.aeb_push(no_auto_open)
    area_element.aeb_push(cursor.anchor_y) -- anchors should be preserved
    area_element.aeb_push(cursor.anchor_x)
    area_element.aeb_push(clipping_side)
    area_element.aeb_push(anchor_pos)
    area_element.aeb_push(mnav.get_clicked(sensor_id) == mb.left or knav.get_action(cell_id) == kba.activate)
    area_element.aeb_push(res_id)
    area_element.aeb_push(state)
    area_element.aeb_push(false) -- selection has changed
    area_element.aeb_push(false) -- contains selection
    area_element.aeb_push(view_request.collapse_top_index) -- aeb_index of the next (up) state
    view_request.collapse_top_index = volatile_data.aeb_index -- put the new view request top index

    area_element.aeb_push_frame_header("collapse", not state.on and no_auto_open)

    stack_manager.push_record()
end

function collapse.finish()
    stack_manager.pop_record()

    area_element.aeb_pop_frame_header("collapse")

    view_request.collapse_top_index = area_element.aeb_pop() -- revert the view request top index
    local contains_selection = area_element.aeb_pop()
    local selection_has_changed = area_element.aeb_pop()
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
    local no_auto_open = area_element.aeb_pop()
    local tid = area_element.aeb_pop()

    cursor.pop_translation()
    cursor.finish_area(true)

    if left_clicked then
        -- interaction from external button
        state.on = not state.on
    elseif not no_auto_open then
        if contains_selection ~= state._collapse_last_contains_selection then
            -- detect selection enter and exit
            state.on = contains_selection
            state._collapse_last_contains_selection = contains_selection
        elseif contains_selection and selection_has_changed then
            -- detect selection movement
            state.on = true
        end
    end

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

    state._collapse_max_size = max_size

    local old_value = state._collapse_size or 0
    if state.on then
        state._collapse_size = follow(state._collapse_size, max_size, speed)
    else
        state._collapse_size = follow(state._collapse_size, 0, speed)
    end

    cursor.change_anchor(anchor_pos)
    cursor[dimension] = state._collapse_size
    reserve.take(res_id)
    mask.push()
    mask.pop()

    if contains_selection then
        if not state.on then
            selection_outline.hide() -- hide the selection outline
        elseif old_value ~= state._collapse_size then -- this collapse is moving
            -- make the selection outline look like it's inside the collapse (even though it isn't)
            cursor.push()
            cursor.change_anchor(0)
            if dimension == "width" then
                cursor.v_stretch(selection_outline_cutoff3)
                cursor.h_stretch(selection_outline_cutoff)
            else
                cursor.v_stretch(selection_outline_cutoff)
                cursor.h_stretch(selection_outline_cutoff3)
            end
            selection_outline.intersect_mask()
            cursor.pop()
        end
    end

    local dx, dy
    if anchor_pos == 0 then
        if clipping_side == "top" then
            dx, dy = 0, state._collapse_size - state._collapse_max_size
        elseif clipping_side == "left" then
            dx, dy = state._collapse_size - state._collapse_max_size, 0
        else
            dx, dy = 0, 0
        end
    else
        if clipping_side == "bottom" then
            dx, dy = 0, state._collapse_max_size - state._collapse_size
        elseif clipping_side == "right" then
            dx, dy = state._collapse_max_size - state._collapse_size, 0
        else
            dx, dy = 0, 0
        end
    end
    cursor.edit_translation(tid, dx, dy)
    state._last_dx = dx
    state._last_dy = dy

    cursor.change_anchor(ax, ay) -- revert anchors
end

return collapse
