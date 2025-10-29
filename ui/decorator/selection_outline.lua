local decorator = require("ui.decorator")
local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local view_request = require("ui.area.view_request")
local draw_queue = require("ui.draw_queue")
local extmath = require("ui.extmath")
local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")

local outset, line_width = decorator.selection_outline_outset, decorator.selection_outline_line_width

local INACTIVE, READY, DONE = 0, 1, 2

---@type `INACTIVE`|`READY`|`DONE`
local mode = INACTIVE
local placement_id
local view_request_placement_id

local hidden = false
local mask_left, mask_top, mask_right, mask_bottom

local selection_outline = {}

---Sets the selection outline location so it can be put in the draw queue later.
---This function behaves like a decorator element and will call cursor.place.
---Also requests scroll regions to put the location into view
function selection_outline.set_placement()
    if mode == INACTIVE then
        cursor.area_expansion_off()
        cursor.place()
        cursor.area_expansion_on()

        view_request.update_collapses()

        -- make a placement without drawing anything yet
        placement_id = draw_data.make_placement(
            placement.left - outset,
            placement.top - outset,
            placement.right + outset,
            placement.bottom + outset
        )

        mode = READY
    end
end

---Makes a new placement for the view request area that is an identical to the selection outline placement.
---This can be used so the view request references its own placement, so that it can be affected differently by translations.
---Only the latest copied placement is used, the older ones are abandoned.
function selection_outline.copy_placement_for_view_request()
    if placement_id then
        view_request_placement_id = draw_data.make_placement(draw_data.get_placement(placement_id))
    end
end

---Adds the selection outline rectangle to the queue. Does not affect the cursor
function selection_outline.add_to_queue()
    if mode == READY then
        -- update function must always run if we are ready, even if we've ended up hiding it.
        view_request.update_auto_scroll(view_request_placement_id or placement_id)

        if not hidden then
            if mask_left then
                draw_queue.push_scissor(mask_left, mask_top, mask_right, mask_bottom)
                -- draw data needs to be manually created since the placement was already made
                draw_data.add_draw_operation(
                    op_ids.rectangle,
                    placement_id,
                    "line",
                    0,
                    0,
                    line_width,
                    unpack(theme.accent_color)
                )
                draw_queue.pop_scissor()
            else
                -- as above
                draw_data.add_draw_operation(
                    op_ids.rectangle,
                    placement_id,
                    "line",
                    0,
                    0,
                    line_width,
                    unpack(theme.accent_color)
                )
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
    placement_id = nil
    view_request_placement_id = nil
end

--#region masking and hiding

---Sets the selection outline mask.
---This function behaves like an element and will call cursor.place.
---Note: add_to_queue uses the current selection outline mask. Any calls to intersect mask after add_to_queue is called won't do anything.
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
