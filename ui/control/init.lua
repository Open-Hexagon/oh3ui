local control = {

    mouse_navigation = require("ui.control.mouse_navigation"),
    keyboard_navigation = require("ui.control.keyboard_navigation"),
    typing = require("ui.control.typing"),
}

control.get_last_used_control_method = require("ui.control.control_data").get_last_used_control_method

return control
