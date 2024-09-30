local cursor = require("ui.cursor")
local anchor = cursor.anchor
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")

---Button element. Can optionally contain text or an icon.
---Text that doesn't fit in the button gets cropped.
---Never reshapes the cursor.
---@param state table
---@param text string?
---@param icon any?
return function(state, text, icon)
    clickbox(state)
    draw_queue.reserve() -- for background
    draw_queue.reserve() -- for outline

    -- draw button internals
    if text or icon then
        cursor.push()
        cursor.inset(element.button_internal_padding)
        primitive.push_mask()
        if text then
            if icon then
            -- icon and text
            else
                -- just text
                cursor.change_anchor(0.5, 0.5)
                primitive.label(text)
            end
        else
            if icon then
                -- just icon
            end
        end
        primitive.pop_mask()
        cursor.pop()
    end

    -- draw background and outline
    draw_queue.take_last_reservation()
    primitive.rectangle_outline(cursor.mouse_intersect.hovering and theme.button_outline_highlight or theme.button_outline)
    draw_queue.take_last_reservation()
    primitive.rectangle(state.holding and theme.button_background_highlight or theme.button_background)

    return state.clicked
end
