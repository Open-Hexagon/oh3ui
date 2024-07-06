local events = require("ui.events")

local keyboard_navigation = {}

local grid = {}

---set cell in grid to value, initializes other cells with 0
---@param x number
---@param y number
---@param value number
local function set_grid_cell(x, y, value)
    for i = 1, y do
        grid[i] = grid[i] or {}
    end
    for i = 1, x do
        grid[y][i] = grid[y][i] or 0
    end
    grid[y][x] = value
end

---get a value in the grid, any undefined cell is 0
---@param x number
---@param y number
---@return number
local function get_grid_cell(x, y)
    local row = grid[y] or {}
    return row[x] or 0
end

local id_counter = 0
local cur_x, cur_y
local selected = 0
local first_position = {}

---reset all initialized values in the grid to 0
function keyboard_navigation.reset()
    for y = 1, #grid do
        for x = 1, #grid[y] do
            grid[y][x] = 0
        end
    end
    id_counter = 0
    first_position.x = nil
    first_position.y = nil
end

---check if an area in the navigation grid is selected
---@param x1 number
---@param y1 number
---@param x2 number?
---@param y2 number?
---@return boolean
function keyboard_navigation.check(x1, y1, x2, y2)
    x2 = x2 or x1
    y2 = y2 or y1
    id_counter = id_counter + 1
    local id = id_counter
    for y = y1, y2 do
        for x = x1, x2 do
            set_grid_cell(x, y, id)
        end
    end
    if first_position.x == nil then
        first_position.x = x1
        first_position.y = y1
    end
    return id == selected
end

---initializes position if nothing is selected, moves otherwise
---@param dx number
---@param dy number
local function move_or_initialize(dx, dy)
    if selected ~= 0 then
        -- move until cell contents change
        local prior_selection = selected
        while selected == prior_selection do
            cur_x = cur_x + dx
            cur_y = cur_y + dy
            selected = get_grid_cell(cur_x, cur_y)
        end
        if selected == 0 then
            -- moved outside grid or in a gap in the grid, go back
            cur_x = cur_x - dx
            cur_y = cur_y - dy
            selected = get_grid_cell(cur_x, cur_y)
        end
    else
        -- initialize, may still be 0 if nothing filled the grid
        cur_x = first_position.x
        cur_y = first_position.y
        if cur_x and cur_y then
            selected = get_grid_cell(cur_x, cur_y)
        end
    end
end

---run the navigation logic using keypressed events, should be called after all check calls are done
function keyboard_navigation.run()
    -- update selected id after grid rebuild
    selected = get_grid_cell(cur_x, cur_y)
    for event in events.iterate("keypressed") do
        local key = event[2]
        if key == "right" then
            move_or_initialize(1, 0)
        elseif key == "left" then
            move_or_initialize(-1, 0)
        elseif key == "down" then
            move_or_initialize(0, 1)
        elseif key == "up" then
            move_or_initialize(0, -1)
        end
    end
end

return keyboard_navigation
