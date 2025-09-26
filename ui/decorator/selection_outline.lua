local element = require("ui.element")
local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local knav = require("ui.control.keyboard_navigation")
local view_request = require("ui.area.view_request")
local draw_queue = require("ui.draw_queue")
local area_element = require("ui.area")
local volatile_data = require("ui.shared_data").volatile
local aeb_stack = volatile_data.aeb_stack

local outset, line_width = element.selection_outline_outset, element.selection_outline_line_width

local INACTIVE, READY, DONE = 0, 1, 2

---@type `INACTIVE`|`READY`|`DONE`
local mode = INACTIVE
local left, top, right, bottom

local selection_outline = {}

---Write a true value to the "add_selection_outline" value in the closest scroll aeb frame header if possible.
local function set_aeb_stack()
    local current_index = area_element.top_frame
    while current_index do
        if aeb_stack[current_index - 1] == "scroll" then
            aeb_stack[current_index - 2] = true
            return
        end
        current_index = aeb_stack[current_index]
    end
end

---Sets the selection outline location so it can be put in the draw queue later.
---This function behaves like a decorator element and will call cursor.place.
---Also requests scroll regions to put the location into view
function selection_outline.set_location()
    if mode == INACTIVE then
        cursor.area_expansion_off()
        cursor.place()

        if knav.selection_has_changed then
            view_request.scroll_into_view(placement.left, placement.top, placement.right, placement.bottom)
            view_request.open_collapses()
        end

        cursor.area_expansion_on()

        left = placement.left - outset
        top = placement.top - outset
        right = placement.right + outset
        bottom = placement.bottom + outset

        set_aeb_stack()

        mode = READY
    end
end

---Adds the selection outline rectangle to the queue. Does not affect the cursor
function selection_outline.add_to_queue()
    if mode == READY then
        draw_queue.rectangle("line", left, top, right, bottom, theme.accent_color, 0, 0, line_width or 1)
        mode = DONE
    end
end

---Should be called at the end of the frame
function selection_outline.reset()
    mode = INACTIVE
end

return selection_outline
