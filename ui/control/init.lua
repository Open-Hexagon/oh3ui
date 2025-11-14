local control = {
    -- only user facing api endpoints should be visible from this table

    mouse_navigation = require("ui.control.mouse_navigation"),
    keyboard_navigation = require("ui.control.keyboard_navigation"),
    typing = require("ui.control.typing"),
}

return control
