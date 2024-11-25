local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local selection_outline = require("ui.element.selection_outline")
local kb_action = require("ui.control.keyboard_navigation").kb_action

---An icon that cycles between other icons when clicked.
---Will reshape the cursor
---@param state table
---@param size number? icon override icon size in pixels (works like a font)
---@param icon_font string? override text.icon_font
---@param ... string icon names
return function(state, size, icon_font, ...)
    local positions = select("#", ...)
    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for cycle button")
        end
        for i = 1, positions do
            state[i] = {}
        end
        state.position = 1
        state.initialized = true
    end

    cursor.push()

    local button_color
    if state.holding then
        button_color = theme.widget_background_highlight
    elseif state.hovering then
        button_color = theme.accent_color
    else
        button_color = theme.white
    end

    if state.clicked then
        state.position = state.position + 1
        if state.position > positions then
            state.position = 1
        end
    end

    cursor.auto_reshape = true
    primitive.icon(select(state.position, ...), size, button_color, icon_font)
    clickbox(state)

    if state.kb_selected then
        selection_outline()
    end

    cursor.do_auto_reshape()
    return state.position
end
