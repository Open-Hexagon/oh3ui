local decorator = require("ui.decorator")
local cursor = require("ui.cursor")
local placement = cursor.placement
local projected_placement = cursor.projected_placement
local theme = require("ui.theme")
local knav = require("ui.control.keyboard_navigation")
local view_request = require("ui.area.view_request")
local draw_queue = require("ui.draw_queue")
local area_element = require("ui.area")
local volatile_data = require("ui.shared_data").volatile
local aeb_stack = volatile_data.aeb_stack
local extmath = require("ui.extmath")

--[[

TODO collapse never actually has to add the selection outline to the queue
TODO after selection outline location is set, the next popped scroll adds it to the queue
TODO when the selection outline gets added to the queue, that is when the view_request data gets calculated
TODO this should cause the view request to use cursor translations as they are now, not when the selection outline location was set
TODO this can be done by having selection outline save its own copy of the cursor when location is placed and restoring it later 

scroll
{
    translate
    {    
        lock
        {
    
    
            collapse
            {
                translate
                {
                    collapse
                    {
                        translate
                        {
                            selection
                        }
                    }
                }
                scroll_into_view
            }
        }
    }
}





]]

local outset, line_width = decorator.selection_outline_outset, decorator.selection_outline_line_width

local INACTIVE, READY, DONE = 0, 1, 2

---@type `INACTIVE`|`READY`|`DONE`
local mode = INACTIVE
local left, top, right, bottom

local hidden = false
local mask_left, mask_top, mask_right, mask_bottom

local selection_outline = {}

-- local x, y, width, height, anchor_x, anchor_y

---Sets the selection outline location so it can be put in the draw queue later.
---This function behaves like a decorator element and will call cursor.place.
---Also requests scroll regions to put the location into view
function selection_outline.set_location()
    if mode == INACTIVE then
        -- x = cursor.x
        -- y = cursor.y
        -- width = cursor.width
        -- height = cursor.height
        -- anchor_x = cursor.anchor_x
        -- anchor_y = cursor.anchor_y

        cursor.area_expansion_off()
        cursor.place()
        cursor.area_expansion_on()

        view_request.update_collapses(knav.selection_has_changed)

        left = placement.left - outset
        top = placement.top - outset
        right = placement.right + outset
        bottom = placement.bottom + outset

        mode = READY
    end
end

local function initiate_auto_scroll()
    cursor.push()
    cursor.x = x
    cursor.y = y
    cursor.width = width
    cursor.height = height
    cursor.anchor_x = anchor_x
    cursor.anchor_y = anchor_y
    cursor.place()
    view_request.scroll_into_view(
        projected_placement.left,
        projected_placement.top,
        projected_placement.right,
        projected_placement.bottom
    )
    cursor.pop()
end

---Adds the selection outline rectangle to the queue. Does not affect the cursor
function selection_outline.add_to_queue()
    if mode == READY then
        if not hidden then
            -- if knav.selection_has_changed then
            --     initiate_auto_scroll()
            -- end
            if mask_left then
                -- draw_queue.push_scissor(mask_left, mask_top, mask_right, mask_bottom)
                draw_queue.rectangle("line", left, top, right, bottom, theme.accent_color, 0, 0, line_width or 1)
                -- draw_queue.pop_scissor()
            else
                draw_queue.rectangle("line", left, top, right, bottom, theme.accent_color, 0, 0, line_width or 1)
            end
        end
        mode = DONE
    end
end

---Should be called at the end of the frame.
function selection_outline.reset()
    mode = INACTIVE
    hidden = false
    mask_left, mask_top, mask_right, mask_bottom = nil, nil, nil, nil
end

--#region masking and hiding

---Sets the selection outline mask.
---This function behaves like a decorator element and will call cursor.place.
function selection_outline.intersect_mask()
    cursor.area_expansion_off()
    cursor.place()
    cursor.area_expansion_on()

    if hidden then -- don't actually do anything if already hidden
        return
    end

    if not mask_left then
        mask_left = placement.left
        mask_top = placement.top
        mask_right = placement.right
        mask_bottom = placement.bottom
    else
        mask_left, mask_top, mask_right, mask_bottom = extmath.aligned_rectangle_intersection(
            mask_left,
            mask_top,
            mask_right,
            mask_bottom,
            placement.left,
            placement.top,
            placement.right,
            placement.bottom
        )
        if not mask_left then -- hide if nothing remains
            hidden = true
        end
    end
end

---Hides the selection outline, even though it's ready
function selection_outline.hide()
    hidden = true
end

--#endregion

return selection_outline
