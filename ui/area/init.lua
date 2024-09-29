-- An area is a generic rectangular bounding box for elements.
-- After an area is started, any new elements that are created will expand the area.
-- Areas can be stacked within each other.
-- The cursor will be set to the area after the area is finished

local area = {}

local area_stack = {}
local area_index = 0

---Start a new area
function area.start()
    -- Add a new area to the stack
    area_index = area_index + 1
    local new_area = area_stack[area_index] or {}
    area_stack[area_index] = new_area

    -- Only create a new table if there is none to reuse
    new_area.bounds = new_area.bounds or {}

    -- Reset bounds
    new_area.bounds.left = nil
    new_area.bounds.top = nil
    new_area.bounds.right = nil
    new_area.bounds.bottom = nil

    -- ? This extra data table might be moved somewhere else
    -- Clear extra data. Make a new table if needed
    new_area.extra_data = new_area.extra_data or {}
    for key in pairs(new_area.extra_data) do
        new_area.extra_data[key] = nil
    end
end

---get an extra data table about the current area (for internal use)
---@return table
function area.get_extra_data()
    return area_stack[area_index].extra_data
end

---get bounds of the currently active area
---@return table
function area.get_bounds()
    return area_stack[area_index].bounds
end

---Sets the cursor to represent the current area bounding rectangle.
function area.put_cursor()
    local cursor = require("ui.cursor")
    local bounds = area.get_bounds()
    cursor.width = bounds.right - bounds.left
    cursor.height = bounds.bottom - bounds.top
    cursor.x = bounds.left + cursor.anchor_x * cursor.width
    cursor.y = bounds.top + cursor.anchor_y * cursor.height
end

---Expand the topmost layer. Should only be called by `cursor.place()`.
---@param left number
---@param top number
---@param right number
---@param bottom number
function area.expand(left, top, right, bottom)
    if area_stack[area_index] then
        local bounds = area_stack[area_index].bounds
        bounds.left = bounds.left == nil and left or math.min(bounds.left, left)
        bounds.top = bounds.top == nil and top or math.min(bounds.top, top)
        bounds.right = bounds.right == nil and right or math.max(bounds.right, right)
        bounds.bottom = bounds.bottom == nil and bottom or math.max(bounds.bottom, bottom)
    end
end

---check if a position is inside the current area
---! may become obsolete
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
---! may become obsolete
---@return boolean
function area.is_mouse_inside()
    local x, y = love.mouse.getPosition()
    return area.is_position_inside(x, y, true)
end

---Finish the last started area.
function area.finish()
    -- Put the current area into the cursor
    area.put_cursor()

    -- The area that's about to be dropped
    local this_area = area_stack[area_index]
    area_index = area_index - 1
    -- The area below
    local last_area = area_stack[area_index]

    if last_area then
        -- Expand the area below to surround the area that's about to be dropped
        last_area.bounds.left = last_area.bounds.left == nil and this_area.bounds.left
            or math.min(last_area.bounds.left, this_area.bounds.left)
        last_area.bounds.right = last_area.bounds.right == nil and this_area.bounds.right
            or math.max(last_area.bounds.right, this_area.bounds.right)
        last_area.bounds.top = last_area.bounds.top == nil and this_area.bounds.top
            or math.min(last_area.bounds.top, this_area.bounds.top)
        last_area.bounds.bottom = last_area.bounds.bottom == nil and this_area.bounds.bottom
            or math.max(last_area.bounds.bottom, this_area.bounds.bottom)
    end
end

return area
