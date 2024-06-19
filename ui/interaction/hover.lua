local hover = {}

---check hover based on mouse position (in element space)
---@param mouse_x number
---@param mouse_y number
---@return boolean
function hover.check(mouse_x, mouse_y)
    local state = require("ui.state")
    return mouse_x >= state.left and mouse_x <= state.right and mouse_y >= state.top and mouse_y <= state.bottom
end

---increment or decrement a timer based on whether the element is hovered (clamped at 0 and 1)
---@param hover_state table
---@param increment number
---@return number
function hover.timer(hover_state, increment)
    local state = require("ui.state")
    hover_state.hover_timer = hover_state.hover_timer or 0
    if state.hovering then
        hover_state.hover_timer = hover_state.hover_timer + increment
        if hover_state.hover_timer > 1 then
            hover_state.hover_timer = 1
        end
    else
        hover_state.hover_timer = hover_state.hover_timer - increment
        if hover_state.hover_timer < 0 then
            hover_state.hover_timer = 0
        end
    end
    return hover_state.hover_timer
end

return hover
