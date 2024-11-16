local effect = {}

---Returns a new value that is closer to the target value.
---@param current number? Value to increment or decrement. If nil, function returns the target value.
---@param target number Value to move towards.
---@param speed number? Speed in units per second.
---@return number
---@nodiscard
function effect.follow(current, target, speed)
    if not current or current == target then
        return target
    end
    speed = speed or 1
    if current < target then
        local new_value = current + speed * love.timer.getDelta()
        if new_value > target then
            new_value = target
        end
        return new_value
    else
        local new_value = current - speed * love.timer.getDelta()
        if new_value < target then
            new_value = target
        end
        return new_value
    end
end

return effect
