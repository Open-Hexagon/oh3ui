local enable_intersection_checks = require("ui.control.mouse_navigation.sensor").enable_intersection_checks
local knav = require("ui.control.keyboard_navigation")
local events = require("ui.events")
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local upvalue = require("tests.upvalue")

local common = {
    unittest_ignore = true,
}

function common.reset_all()
    events.clear()
    control_data.current_layer_is_active = false
    enable_intersection_checks()

    knav.set_wrapping()
    knav.set_page_length(1)

    -- need both for complete reset
    knav.reset()
    knav.deselect()
end

function common.get_selected_cell_info()
    return upvalue.get_by_name(knav.deselect, "selected_cell_id", "grid_x", "grid_y")
end

return common
