local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local selection_outline = require("ui.decorator.selection_outline")
local kba = require("ui.control.keyboard_action")
local knav = require("ui.control.keyboard_navigation")

---An icon that can be clicked.
---Will reshape the cursor
---@param state table
---@param size number icon override icon size in pixels (works like a font)
---@param icon_name string icon name
---@return integer clicked the "clicked" field of the state table
return function(state, size, icon_name)
    cursor.push()

    local button_color
    if state.holding then
        button_color = theme.widget_background_highlight
    elseif state.hovering or knav.get_holding() == kba.activate then
        button_color = theme.accent_color
    else
        button_color = theme.white
    end

    cursor.auto_reshape = true
    primitive.icon(icon_name, size, button_color)
    clickbox(state)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape()
    return state.clicked
end
