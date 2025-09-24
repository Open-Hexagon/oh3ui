local element = require("ui.element")
local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local knav = require("ui.control.keyboard_navigation")
local scroll_into_view = require("ui.element.area.scroll.view_request").scroll_into_view
local draw_queue = require("ui.draw_queue")
local warning = require("ui.warning")

local outset, line_width = element.selection_outline_outset, element.selection_outline_line_width

local INACTIVE, READY, DONE = 0, 1, 2

---@type `INACTIVE`|`READY`|`DONE`
local mode = INACTIVE
local left, top, right, bottom

local selection_outline = {}

---Sets the selection outline location so it can be put in the draw queue later.
---This function behaves like a decorator element and will call cursor.place.
---Also requests scroll regions to put the location into view
function selection_outline.set_location()
    if mode ~= INACTIVE then
        return
    end

    cursor.area_expansion_off()
    cursor.place()

    if knav.selection_has_changed then
        scroll_into_view(placement.left, placement.top, placement.right, placement.bottom)
    end

    cursor.area_expansion_on()

    left = placement.left - outset
    top = placement.top - outset
    right = placement.right + outset
    bottom = placement.bottom + outset

    mode = READY
end

---Adds the selection outline rectangle to the queue. Does not affect the cursor
function selection_outline.add_to_queue()
    if mode ~= READY then
        return
    end
    draw_queue.rectangle("line", left, top, right, bottom, theme.accent_color, 0, 0, line_width or 1)
    mode = DONE
end

---Should be called at the end of the frame
function selection_outline.reset()
    mode = INACTIVE
end

return selection_outline
