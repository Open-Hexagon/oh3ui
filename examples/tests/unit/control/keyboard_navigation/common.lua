local enable_intersection_checks = require("ui.control.sensor").enable_intersection_checks
local knav = require("ui.control.keyboard_navigation")
local events = require("ui.events")
local layer_status = require("ui.layer")

local common = {
    unittest_ignore = true,
}

function common.reset_all()
    events.clear()
    layer_status.current_layer_is_active = false
    enable_intersection_checks()

    knav.set_wrapping()
    knav.set_page_length(1)

    -- need all for complete reset
    knav.reset()
    knav.deselect()
    knav.evaluate_without_events()
end

return common
