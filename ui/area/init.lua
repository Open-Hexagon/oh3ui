local view_request = require("ui.area.view_request")

local area_element = {
    background = require("ui.area.element.background"),
    blank_background = require("ui.area.element.blank_background"),
    collapse = require("ui.area.element.collapse"),
    scroll = require("ui.area.element.scroll"),
}

function area_element.is_auto_scroll_active()
    return view_request.time > 0
end

return area_element
