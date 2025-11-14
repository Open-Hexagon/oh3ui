local layer_status = {
    current_layer_is_active = false,
    current_layer = 0,
}

function layer_status.is_current_layer_active()
    return layer_status.current_layer_is_active
end

function layer_status.get_current_layer()
    return layer_status.current_layer
end

return layer_status
