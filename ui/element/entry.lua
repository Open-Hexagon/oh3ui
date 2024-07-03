local state = require("ui.state")
local theme = require("ui.theme")
local area = require("ui.area")
local scroll = require("ui.area.scroll")
local label = require("ui.element.label")
local draw_queue = require("ui.draw_queue")
local click = require("ui.interaction.click")
local text_interaction = require("ui.interaction.text")

---text entry element
---@param entry_state table
return function(entry_state)
    state.update()
    local height = state.height
    if click.clicking then
        entry_state.selected = state.hovering
    end

    -- background rectangle
    draw_queue.rectangle("fill", state.left, state.top, state.right, state.bottom, theme.rectangle_color)

    -- scroll text to side if required
    entry_state.scroll_state = entry_state.scroll_state or {}
    scroll.start(entry_state.scroll_state, "horizontal", state.width)

    -- cursor
    if entry_state.selected then
        entry_state.cursor_pos = entry_state.cursor_pos or 0
        local x = state.left + entry_state.cursor_pos
        draw_queue.rectangle("fill", x - 1, state.top + 2, x + 1, state.bottom - 2, theme.label_color)
    end

    -- text
    text_interaction.update(entry_state)
    label(entry_state.text)

    -- adjust bounds of area to match height
    local bounds = area.get_bounds()
    bounds.bottom = bounds.top + height

    scroll.done()
end
