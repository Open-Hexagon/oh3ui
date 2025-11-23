local backend = {
    ---@type "none"|"mouse"|"keyboard"|"typing"
    last_used_control_method = "none",
}

function backend.get_last_used_control_method()
    return backend.last_used_control_method
end

return backend
