local ui_settings = require("ui.settings")

---@param message string
return function(message)
    if ui_settings.strict then
        error(message, 2)
    else
        -- strict mode is always on for unit testing
        -- luacov: disable
        io.stderr:write("warning: ", message)
        -- luacov: enable
    end
end
