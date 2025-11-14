local control_backend = require("ui.control.backend")

local control = {
    -- only user facing api endpoints should be visible from this table

    mouse_navigation = require("ui.control.mouse_navigation"),
    keyboard_navigation = require("ui.control.keyboard_navigation"),
    typing = require("ui.control.typing"),
}


function control.get_last_used_control_method()
    return control_backend.last_used_control_method
end

return control
