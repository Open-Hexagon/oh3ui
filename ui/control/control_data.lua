local control_data = {
    ---@type "none"|"mouse"|"keyboard"|"typing"
    last_used_control_method = "none",
}

function control_data.get_last_used_control_method()
    return control_data.last_used_control_method
end

return control_data
