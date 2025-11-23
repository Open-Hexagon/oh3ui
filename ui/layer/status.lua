local status = {
    current_layer_is_active = false,
    current_layer = 0,
}

function status.is_current_layer_active()
    return status.current_layer_is_active
end

function status.get_current_layer()
    return status.current_layer
end

return status
