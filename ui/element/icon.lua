local label = require("ui.element.label")
local state = require("ui.state")

---icon element (may auto resize)
---@param icon_id string
---@param icon_font string?  uses bootstrap icons by default
return function(icon_id, icon_font)
    -- set font to icon font
    local old_font = state.font
    state.font = icon_font or "assets/bootstrap-icons.ttf"

    -- get icon id table
    local icon_id_table = state.get_icon_font_ids()
    if not icon_id_table then
        error("Could not find icon id table for font!")
    end

    -- get string that results in icon using this font
    local str = icon_id_table[icon_id]
    if not str then
        error("Invalid icon id " .. str)
    end
    label(str)  -- an icon with an icon font is just text, so a label

    -- revert to old font
    state.font = old_font
end
