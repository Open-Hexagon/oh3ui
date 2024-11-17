local events = require("ui.events")

local keyboard_navigation = {}

---Grid cell values that trigger special actions when navigating with arrow keys
---Real cell values are strictly positive.
local special_cell = {
    nothing = 0, -- navigation can freely pass through this cell
    barrier = -1, -- when encountered, navigation is stopped
    wrap = -2, -- when encountered, navigation is wrapped to the closest wrap or barrier cell in the opposite navigation direction
    tab = -3, -- when encountered, navigation is jumped to the previous or next tab selection
}

---This influences what get_grid_cell sees when it looks outside the bounds of the grid
---@type "vertical"|"horizontal"|"line"|"both"|"both_line"|nil
local wrapping_mode

---Set navigation behavior of grid borders.
---@param mode?
---|"vertical" navigation is wrapped if it reaches the top or bottom grid borders
---|"horizontal" navigation is wrapped if it reaches the left or right grid borders
---|"line" horizontal navigation wraps like text wrapping would using the tab order
---|"both" union of vertical and horizontal
---|"both_line" union of vertical and line
function keyboard_navigation.set_wrapping(mode)
    wrapping_mode = mode
end

---Grid used to assist in determining what the arrow keys will do
---This grid can be sparse with holes and maybe entire missing rows
local grid = {}
---Grid size. This enforces the grid borders.
local grid_width, grid_height = 0, 0
---Grid cursor location. The location where navigation starts. A cell can be selected but have an undefined navigation location.
local grid_x, grid_y

---Fills a rectangular region of the grid with some value
---@param value integer
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
local function fill_grid(value, x1, y1, x2, y2)
    grid_width = math.max(grid_width, x2)
    grid_height = math.max(grid_height, y2)
    for y = y1, y2 do
        grid[y] = grid[y] or {}
        for x = x1, x2 do
            grid[y][x] = value
        end
    end
end

---Erases all grid values and resets grid_width and grid_height
local function erase_grid()
    for y = 1, grid_height do
        if grid[y] then
            for x = 1, grid_width do
                grid[y][x] = nil
            end
        end
    end
    grid_width, grid_height = 0, 0
end

---Get a grid cell's value. Any undefined region within the grid is read back as 0.
---Areas outside the grid are read back as barriers or wraps, depending on the wrap mode.
---@param x integer
---@param y integer
---@return integer
local function get_grid_cell(x, y)
    if x < 1 or x > grid_width then
        -- x coordinate exceeds grid size
        if wrapping_mode == "horizontal" or wrapping_mode == "both" then
            return special_cell.wrap
        elseif wrapping_mode == "line" or wrapping_mode == "both_line" then
            return special_cell.tab
        else
            return special_cell.barrier
        end
    end
    if y < 1 or y > grid_height then
        -- y coordinate exceeds grid size
        if wrapping_mode == "vertical" or wrapping_mode == "both" or wrapping_mode == "both_line" then
            return special_cell.wrap
        end
        return special_cell.barrier
    end
    local row = grid[y]
    if not row then
        return special_cell.nothing
    end
    return row[x] or special_cell.nothing
end

---An ordered list of created cells
local cell_list = {}
---Hold the index of the last created cell
local cell_index = 0
---The index of the currently selected cell.
---0 indicates no selection.
local selected_cell = 0

---The index of the cell that gets activated if escape is pressed.
---nil means there was no cell set.
---0 indicates the next cell's index will be put in this variable
local escape_cell
---The index of the cell that gets activated if enter is pressed while nothing is selected
---nil means there was no cell set.
---0 indicates the next cell's index will be put in this variable
local default_cell

---Create a keyboard navigation cell which can be selected. The order in which these are called determines the tab order.
---@param mode?
---|"default" make this cell the default cell
---|"escape" make this cell the escape cell
---|"both" make this cell both the default and escape cell
function keyboard_navigation.make_cell(mode)
    -- add a cell to the list
    cell_index = cell_index + 1
    cell_list[cell_index] = cell_list[cell_index] or {}

    if mode == "escape" or mode == "both" then
        escape_cell = cell_index
    end

    if mode == "default" or mode == "both" then
        default_cell = cell_index
    end

    return cell_index == selected_cell
end

-- ! There's no protection against overwriting already existing cell values.
-- ! Allowing overwriting may be useful but may also cause strange behavior.

---Fills a rectangle in the grid with the last created cell index.
---If this function isn't run after a make_cell call, then that cell can be tabbed to but not selected via navigating the grid.
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.grid_cell(x, y, col_span, row_span)
    col_span = col_span or 1
    row_span = row_span or 1
    if x < 1 or y < 1 or col_span < 1 or row_span < 1 then
        error("bad grid cell rectangle")
    end
    fill_grid(cell_index, x, y, x + col_span - 1, y + row_span - 1)
    cell_list[cell_index].x = x
    cell_list[cell_index].y = y
end

local function jump_to_cell(new_selection)
    grid_x = cell_list[new_selection].x
    grid_y = cell_list[new_selection].y
    selected_cell = new_selection
end

local function jump_forward()
    if selected_cell >= cell_index then
        jump_to_cell(1)
    else
        jump_to_cell(selected_cell + 1)
    end
end

local function jump_backwards()
    if selected_cell <= 1 then
        jump_to_cell(cell_index)
    else
        jump_to_cell(selected_cell - 1)
    end
end

local MAX_SEARCH_DISTANCE = 256

---Finds a border between two different cell values by walking in a given direction.
---The cell under the starting coordinate isn't actually checked, so the starting_value can be different than the value in that cell.
---@param starting_value integer Function walks until it encounters a cell value that is different from this is value
---@param x integer Starting coordinate
---@param y integer Starting coordinate
---@param dx integer Walk step
---@param dy integer Walk step
---@return integer inside_x Coordinate right inside the border
---@return integer inside_y Coordinate right inside the border
---@return integer outside_x Coordinate right outside the border
---@return integer outside_y Coordinate right outside the border
---@return integer encountered_value Value across border
local function find_border(starting_value, x, y, dx, dy)
    for _ = 1, MAX_SEARCH_DISTANCE do
        local next_x, next_y = x + dx, y + dy
        local encountered_value = get_grid_cell(next_x, next_y)
        if encountered_value ~= starting_value then
            return x, y, next_x, next_y, encountered_value
        end
        x = next_x
        y = next_y
    end
    error("couldn't find a border within a reasonable range")
end

local function find_barriers(x, y, dx, dy)
    for _ = 1, MAX_SEARCH_DISTANCE do
        local encountered_value = get_grid_cell(x, y)
        if encountered_value == special_cell.barrier or encountered_value == special_cell.wrap then
            return x, y
        end
        x = x + dx
        y = y + dy
    end
    error("couldn't find a barrier or wrap within a reasonable range")
end

local function tab_navigate(mode)
    if mode == "right" or mode == "down" then
        jump_forward()
    elseif mode == "left" or mode == "up" then
        jump_backwards()
    end
end

local function wrap_navigate(mode) end

local function navigate_grid(mode)
    -- if nothing is selected or selection position is undefined, use tab ordering
    if selected_cell == 0 or not grid_x then
        tab_navigate(mode)
        return
    end
    local original_selection = get_grid_cell(grid_x, grid_y)
    -- if the grid cursor is not on a proper cell, jump to the first cell
    if original_selection < 1 then
        keyboard_navigation.back_to_top()
        return
    end

    local dx, dy, _
    if mode == "right" then
        dx, dy = 1, 0
    elseif mode == "left" then
        dx, dy = -1, 0
    elseif mode == "down" then
        dx, dy = 0, 1
    elseif mode == "up" then
        dx, dy = 0, -1
    end

    -- Search for the border of our current cell region
    local inside_x, inside_y, outside_x, outside_y, encountered_cell =
        find_border(original_selection, grid_x, grid_y, dx, dy)

    if encountered_cell == special_cell.nothing then
        -- encountered a nothing cell
        -- move the outside coordinates and change the encountered cell type so as if the nothing cells weren't there
        _, _, outside_x, outside_y, encountered_cell = find_border(special_cell.nothing, outside_x, outside_y, dx, dy)
    end

    if encountered_cell == special_cell.wrap then
        -- locate a barrier in the opposite direction
        local barrier_x, barrier_y = find_barriers(grid_x, grid_y, -dx, -dy)

        -- search for a border, starting at the barrier
        local wrap_x, wrap_y, wrap_encountered_cell
        _, _, wrap_x, wrap_y, wrap_encountered_cell = find_border(special_cell.nothing, barrier_x, barrier_y, dx, dy)

        if wrap_encountered_cell == original_selection then
            -- we found the same cell again
            -- wrapping behaves like a barrier in this case
            grid_x, grid_y = inside_x, inside_y
        else
            -- we found a different cell
            grid_x, grid_y = wrap_x, wrap_y
            selected_cell = wrap_encountered_cell
        end
    elseif encountered_cell == special_cell.tab then
        tab_navigate(mode)
    elseif encountered_cell == special_cell.barrier then
        -- encountered a barrier
        grid_x, grid_y = inside_x, inside_y
    else
        -- encountered a different cell
        grid_x, grid_y = outside_x, outside_y
        selected_cell = encountered_cell
    end
end

function keyboard_navigation.deactivate()
    selected_cell = 0
    grid_x, grid_y = nil, nil
end

function keyboard_navigation.back_to_top()
    jump_to_cell(1)
end

---Prints the grid to the console
function keyboard_navigation.print_grid() end

---run the navigation logic using keypressed events
function keyboard_navigation.evaluate()
    if cell_index < 1 then
        -- no cells were created
        return
    end

    for event in events.iterate("keypressed") do
        local key = event[2]

        if key == "tab" then
            if love.keyboard.isDown("lshift", "rshift") then
                jump_backwards()
            else
                jump_forward()
            end
        elseif key == "return" then
            if selected_cell == 0 then
                if default_cell then
                    jump_to_cell(default_cell)
                    print("activated", default_cell)
                end
            else
                print("activated", selected_cell)
            end
        elseif key == "escape" then
            if escape_cell then
                jump_to_cell(escape_cell)
                print("escaped", escape_cell)
            end
        elseif key == "right" or key == "left" or key == "down" or key == "up" then
            navigate_grid(key)
        elseif key == "f8" then -- debug key
            keyboard_navigation.deactivate()
        end
    end

    erase_grid()
    cell_index = 0
    default_cell = nil
    escape_cell = nil
end

return keyboard_navigation
