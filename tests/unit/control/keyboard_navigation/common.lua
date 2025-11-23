local enable_intersection_checks = require("ui.control.sensor").enable_intersection_checks
local knav = require("ui.control.keyboard_navigation")
local backend = require("ui.control.backend")
local events = require("ui.events")
local layer_backend = require("ui.layer.backend")

local common = {
    unittest_ignore = true,
}

function common.reset_all()
    events.clear()
    layer_backend.current_layer_is_active = false
    enable_intersection_checks()

    knav.set_wrapping()
    knav.set_page_length(1)

    -- need all for complete reset
    backend.keyboard_navigation_reset()
    backend.keyboard_navigation_deselect()
    backend.keyboard_navigation_evaluate_without_events()
end

return common
