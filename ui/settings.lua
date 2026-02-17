local platform = love.system.getOS()

local settings = {
    scale = 1,
    strict = nil,
    overlay_grid = nil,
    overlay_masks = nil,
    overlay_mouse_sensors = nil,
    overlay_view_request = nil,
    is_desktop = not (platform == "Android" or platform == "iOS"),
}

return settings
