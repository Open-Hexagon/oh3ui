local cursor = require("ui.cursor")
local theme = require("ui.theme")
local primitive = require("ui.primitive")
local selection_outline = require("ui.decorator.selection_outline")
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local smode = mnav.sensor_mode

---An icon that can be clicked.
---Will reshape the cursor
---@param size number override icon size in pixels (works like a font)
---@param icon_name string icon name
---@return mouse_button? clicked the "clicked" field of the state table
return function(size, icon_name)
    cursor.push()

    local sid = mnav.declare_sensor_id()

    local button_color
    if mnav.get_holding(sid) then
        button_color = theme.widget_background_highlight
    elseif knav.get_holding() == kba.activate then
        if mnav.is_hovering(sid) then
            button_color = theme.widget_background_highlight
        else
            button_color = theme.accent_color
        end
    elseif mnav.is_hovering(sid) then
        button_color = theme.accent_color
    else
        button_color = theme.white
    end

    cursor.auto_reshape = true
    primitive.icon(icon_name, size, button_color)
    mnav.make_sensor(sid, smode.block)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape()
    return mnav.get_clicked(sid)
end
