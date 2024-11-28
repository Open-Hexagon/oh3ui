local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local selection_outline = require("ui.element.selection_outline")
local mb = require("ui.control.mouse_button")
local kba = require("ui.control.keyboard_action")

---An icon that cycles between other icons when left or right clicked.
---Will reshape the cursor.
---@param state table
---@param size number? icon override icon size in pixels (works like a font)
---@param icon_font string? override text.icon_font
---@param ... string icon names
---@return integer position the "position" field of the state table
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

    if not state.kb_is_repeat then
        if state.clicked == mb.left or state.kb_action == kba.right or state.kb_action == kba.activate then
            state.position = state.position + 1
            if state.position > positions then
                state.position = 1
            end
        elseif state.clicked == mb.right or state.kb_action == kba.left then
            state.position = state.position - 1
            if state.position < 1 then
                state.position = positions
            end
        end
    end

    cursor.push()

    local button_color
    if state.holding then
        button_color = theme.widget_background_highlight
    elseif state.hovering or state.kb_holding == kba.activate then
        button_color = theme.accent_color
    else
        button_color = theme.white
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
