local events = require("ui.events")

local keyboard_navigation = {}

---Grid cell values that trigger special actions when navigating with arrow keys
---Real cell values are strictly positive.
local special_cell = {
    nothing = 0, -- navigation can freely pass through this cell
    barrier = -1, -- when encountered, navigation is stopped, as if it reached the boundary of the grid
    wrap = -2, -- when encountered, navigation is wrapped to the closest wrap cell or the border of the grid in the opposite navigation direction
}

---@type "vertical"|"horizontal"|"both"|nil
local wrapping_mode

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
        if wrapping_mode == "horizontal" or wrapping_mode == "both" then
            return special_cell.wrap
        end
        return special_cell.barrier
    end
    if y < 1 or y > grid_height then
        if wrapping_mode == "vertical" or wrapping_mode == "both" then
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

---Set navigation behavior of grid borders.
---@param mode?
---|"vertical" navigation is wrapped if it reaches the top or bottom grid borders
---|"horizontal" navigation is wrapped if it reaches the left or right grid borders
---|"both" union of vertical and horizontal
function keyboard_navigation.set_wrapping(mode)
    wrapping_mode = mode
end

---The next created cell will be the default cell This will override the previous default cell
function keyboard_navigation.next_as_default()
    default_cell = 0
end

---The next created cell will be the escape cell. This will override the previous escape cell
function keyboard_navigation.next_as_escape()
    escape_cell = 0
end

---Create a keyboard navigation cell which can be selected. The order in which these are called determines the tab order.
function keyboard_navigation.make_cell()
    -- add a cell to the list
    cell_index = cell_index + 1
    cell_list[cell_index] = cell_list[cell_index] or {}

    -- these don't have to be mutually exclusive
    if escape_cell == 0 then
        escape_cell = cell_index
    end
    if default_cell == 0 then
        default_cell = cell_index
    end

    return cell_index == selected_cell
end

function keyboard_navigation.is_selected() end

-- ! There's no protection against overwriting already existing cell values.
-- ! Allowing overwriting may be useful button may also cause strange behavior.

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

---Fills a rectangle in the grid with barriers.
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.grid_barrier(x, y, col_span, row_span)
    col_span = col_span or 1
    row_span = row_span or 1
    if x < 1 or y < 1 or col_span < 1 or row_span < 1 then
        error("bad grid cell rectangle")
    end
    fill_grid(special_cell.barrier, x, y, x + col_span - 1, y + row_span - 1)
end

---Fills a rectangle in the grid with wraps.
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.grid_wrap(x, y, col_span, row_span)
    col_span = col_span or 1
    row_span = row_span or 1
    if x < 1 or y < 1 or col_span < 1 or row_span < 1 then
        error("bad grid cell rectangle")
    end
    fill_grid(special_cell.wrap, x, y, x + col_span - 1, y + row_span - 1)
end

local function jump_to_cell(new_selection)
    grid_x = cell_list[new_selection].x
    grid_y = cell_list[new_selection].y
    print(grid_x, grid_y)
    selected_cell = new_selection
end

local function navigate_grid(mode)
    -- make sure we're in a proper grid location
    -- if nothing is selected or grid location is undefined, jump to the first cell
    if selected_cell == 0 or not grid_x then
        jump_to_cell(1)
    end

    local original_grid_cell = get_grid_cell(grid_x, grid_y)

    -- if the grid cursor is not on a proper cell, jump to the first cell
    if original_grid_cell < 1 then
        jump_to_cell(1)
    end

    if mode == "right" then
        local n = 0
        local following_selection
        repeat
            n = n + 1
            following_selection = get_grid_cell(grid_x + n, grid_y)
        until following_selection ~= original_grid_cell

        if following_selection == special_cell.nothing then
            repeat
                n = n + 1
                following_selection = get_grid_cell(grid_x + n, grid_y)
            until following_selection ~= special_cell.nothing
        elseif following_selection == special_cell.barrier then
        elseif following_selection == special_cell.wrap then
        else
        end
    elseif mode == "left" then
    elseif mode == "down" then
    elseif mode == "up" then
    end
end

function keyboard_navigation.clear_selection()
    selected_cell = 0
    grid_x, grid_y = nil, nil
end

---Prints the grid to the console
function keyboard_navigation.print_grid() end

---run the navigation logic using keypressed events
function keyboard_navigation.evaluate()
    if escape_cell == 0 or default_cell == 0 then
        -- cells were primed to be set but never were
        error("escape or default cell not set properly")
    end

    if cell_index >= 0 then
        for event in events.iterate("keypressed") do
            local key = event[2]

            if key == "tab" then
                if love.keyboard.isDown("lshift", "rshift") then
                    -- reverse tabbing
                    if selected_cell <= 1 then
                        jump_to_cell(cell_index)
                    else
                        jump_to_cell(selected_cell - 1)
                    end
                else
                    -- forward tabbing
                    if selected_cell >= cell_index then
                        jump_to_cell(1)
                    else
                        jump_to_cell(selected_cell + 1)
                    end
                end
                print("tabbed to", selected_cell)
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
            elseif key == "q" then -- debug key
                keyboard_navigation.clear_selection()
            end
        end
    end

    cell_index = 0
    grid_width, grid_height = 0, 0
    default_cell = nil
    escape_cell = nil
end

return keyboard_navigation
