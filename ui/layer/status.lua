local status = {
    knav_allowed = false,
    mnav_allowed = false,
    current_layer_number = 0,
}

function status.is_knav_allowed_on_current_layer()
    return status.knav_allowed
end

function status.is_mnav_allowed_on_current_layer()
    return status.mnav_allowed
end

function status.get_current_layer_number()
    return status.current_layer_number
end

return status
