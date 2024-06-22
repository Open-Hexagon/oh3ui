local state = require("ui.state")
local area = {}

---start a new area (can be inside an area)
function area.start()
    -- add a new area to the stack
    state.current_area_index = state.current_area_index + 1
    local new_area = state.areas[state.current_area_index] or {}
    state.areas[state.current_area_index] = new_area

    -- only create a new table if there is none to reuse
    new_area.bounds = new_area.bounds or {}

    -- reset bounds (they are updated in state update)
    new_area.bounds.left = nil
    new_area.bounds.top = nil
    new_area.bounds.right = nil
    new_area.bounds.bottom = nil

    -- clear extra data
    new_area.extra_data = new_area.extra_data or {}
    for key in pairs(new_area.extra_data) do
        new_area.extra_data[key] = nil
    end
end

---get an extra data table about the current area (for internal use)
---@return table
function area.get_extra_data()
    return state.areas[state.current_area_index].extra_data
end

---get bounds of the currently active area
---@return table
function area.get_bounds()
    return state.areas[state.current_area_index].bounds
end

---sets the current state to represent the area bounding rect
function area.set_state_to_bounds()
    local bounds = area.get_bounds()
    state.width = bounds.right - bounds.left
    state.height = bounds.bottom - bounds.top
    state.x = state.left + state.anchor.x * state.width
    state.y = state.top + state.anchor.y * state.height
end

---check if a position is inside the current area
---@param x number
---@param y number
---@param is_screen_space boolean?
---@return boolean
function area.is_position_inside(x, y, is_screen_space)
    if is_screen_space then
        x, y = love.graphics.inverseTransformPoint(x, y)
    end
    local bounds = area.get_bounds()
    return x >= bounds.left and x <= bounds.right and y >= bounds.top and y <= bounds.bottom
end

---check if mouse is inside the current area
---@return boolean
function area.is_mouse_inside()
    local x, y = love.mouse.getPosition()
    return area.is_position_inside(x, y, true)
end

---finish the area started last
function area.done()
    local this_area = state.areas[state.current_area_index]
    state.current_area_index = state.current_area_index - 1
    local last_area = state.areas[state.current_area_index]
    if last_area then
        love.graphics.setCanvas(last_area.canvas)
        -- update bounds of lower area
        last_area.bounds.left = last_area.bounds.left == nil and this_area.bounds.left or math.min(last_area.bounds.left, this_area.bounds.left)
        last_area.bounds.right = last_area.bounds.right == nil and this_area.bounds.right or math.max(last_area.bounds.right, this_area.bounds.right)
        last_area.bounds.top = last_area.bounds.top == nil and this_area.bounds.top or math.min(last_area.bounds.top, this_area.bounds.top)
        last_area.bounds.bottom = last_area.bounds.bottom == nil and this_area.bounds.bottom or math.max(last_area.bounds.bottom, this_area.bounds.bottom)
    else
        love.graphics.setCanvas()
    end
end

return area
