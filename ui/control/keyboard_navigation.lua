local events = require("ui.events")
local bit = require("bit")
local bor, band = bit.bor, bit.band

local keyboard_navigation = {
    selection_has_changed = false
}

---@enum keyboard_action
keyboard_navigation.actions = {
    activate = 0,
    left = 1,
    right = 2,
    up = 3,
    down = 4,
}

local kba = keyboard_navigation.actions

---Operational grid cell values that trigger special actions when navigating with arrow keys.
---Normal cell values are strictly positive.
---@enum op_cell
keyboard_navigation.op_cell = {
    nothing = 0, -- navigation can freely pass through this cell
    barrier = -1, -- when encountered, navigation is stopped
    wrap = -2, -- when encountered, navigation is wrapped to the closest wrap or barrier cell in the opposite navigation direction
    tab = -3, -- when encountered, navigation is jumped to the previous or next tab selection
    redirect = -4, -- when encountered, any navigation movement is cancelled and the arrow key input is saved as the last input instead
    page = -5, -- when encountered, navigation is jumped to the previous or next page
}

local op_cell = keyboard_navigation.op_cell

local page_length = 1

---Sets how many items forward or backwards to move when encountering the page op_cell or using the pageup or pagedown keys
---@param n integer
function keyboard_navigation.set_page_length(n)
    if n < 1 then
        error("page length cannot be less than 1")
    end
    page_length = n
end

---@enum wrapping_mode
keyboard_navigation.wrapping_mode = {
    horizontal = 0x01, -- if grid_x is out of bounds, navigation will see wrap op cells
    line = 0x02, -- if grid_x is out of bounds, navigation will see tab op cells
    list = 0x04, -- if grid_x is out of bounds, navigation will see redirect op cells
    page = 0x08, -- if grid_x is out of bounds, navigation will see page op cells
    vertical = 0x10, -- if grid_y is out of bounds, navigation will see wrap op cells
}

local wmode = keyboard_navigation.wrapping_mode

---A bit packed integer that influences what `get_grid_cell` sees when it looks outside the bounds of the grid.\
---**Bit packing**
---
---```text
---bit 5 4 3 2 1
---MSB 0 0 0 0 0 LSB
---```
---1. horizontal wrapping
---2. line wrapping
---3. list wrapping
---4. page wrapping
---5. vertical wrapping
---@type integer
local wrapping_mode = 0

---Set navigation behavior of grid borders.
---@param ... wrapping_mode list of wrapping mode enums
function keyboard_navigation.set_wrapping(...)
    wrapping_mode = bor(0, ...)
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
        if band(wrapping_mode, wmode.horizontal) ~= 0 then
            return op_cell.wrap
        elseif band(wrapping_mode, wmode.line) ~= 0 then
            return op_cell.tab
        elseif band(wrapping_mode, wmode.list) ~= 0 then
            return op_cell.redirect
        elseif band(wrapping_mode, wmode.page) ~= 0 then
            return op_cell.page
        else
            return op_cell.barrier
        end
    end

    if y < 1 or y > grid_height then
        -- y coordinate exceeds grid size
        if band(wrapping_mode, wmode.vertical) > 0 then
            return op_cell.wrap
        else
            return op_cell.barrier
        end
    end

    local row = grid[y]
    if not row then
        return op_cell.nothing
    end
    return row[x] or op_cell.nothing
end

---An ordered list of created cells
local cell_list = {}

---Holds the index of the last created cell.
---Is also the length of the cell list.
local cell_index = 0

---The index of the currently selected cell.
---0 indicates no selection.
local selected_cell = 0

---The index of the cell that gets activated if escape is pressed.
---nil means there was no cell set.
local escape_cell
---The index of the cell that gets activated if enter is pressed while nothing is selected
---nil means there was no cell set.
local default_cell

---The last performed keyboard action. Nil if there was no action.
---There only needs to be one since the keyboard can only interact with one thing at a time.
---@type keyboard_action?
local last_action
---The whether the last keyboard action is a repeated one
---There only needs to be one since the keyboard can only interact with one thing at a time.
local last_is_repeat

---The key name that is currently being held down. Only the latest pressed key is considered "held".
---@type string?
local holding_key

---Converts love2d key names to keyboard actions
local key_to_action = {
    ["return"] = kba.activate,
    ["space"] = kba.activate,
    ["escape"] = kba.activate,
    ["right"] = kba.right,
    ["left"] = kba.left,
    ["down"] = kba.down,
    ["up"] = kba.up,
}

---Resets keyboard navigation to its initial state, leaving no cell selected.
function keyboard_navigation.deactivate()
    selected_cell = 0
    grid_x, grid_y = nil, nil
end

---Create a keyboard navigation cell which can be selected. The order in which these are called determines the tab order.
---@param mode?
---|"default" make this cell the default cell
---|"escape" make this cell the escape cell
---|"both" make this cell both the default and escape cell
---@return integer cell_id id number of this cell
function keyboard_navigation.make_cell(mode)
    cell_index = cell_index + 1

    local cell = cell_list[cell_index]
    if cell then
        --erase old fields
        cell.x = nil
        cell.y = nil
    else
        cell_list[cell_index] = {}
    end

    if mode == "escape" or mode == "both" then
        escape_cell = cell_index
    end

    if mode == "default" or mode == "both" then
        default_cell = cell_index
    end

    return cell_index
end

---You can use is_selected and get_action to get immedtate values from the navigation.

---Returns true if the last created cell or specified cell is selected
---@param cell_id? integer
---@return boolean
function keyboard_navigation.is_selected(cell_id)
    cell_id = cell_id or cell_index
    return cell_id > 0 and cell_id == selected_cell
end

---Returns the action of the last created cell
---@param cell_id? integer
---@return keyboard_action?
function keyboard_navigation.get_action(cell_id)
    if keyboard_navigation.is_selected(cell_id) then
        return last_action
    end
    return nil
end

---Returns the repeat state of the action on the last created cell
---@param cell_id? integer
---@return boolean?
function keyboard_navigation.is_repeat(cell_id)
    if keyboard_navigation.is_selected(cell_id) then
        return last_is_repeat
    end
    return nil
end

---Returns the holding action of the last created cell
---@param cell_id? integer
---@return keyboard_action?
function keyboard_navigation.get_holding(cell_id)
    if keyboard_navigation.is_selected(cell_id) then
        return key_to_action[holding_key]
    end
    return nil
end

-- ! There's no protection against overwriting already existing cell values.
-- ! Allowing overwriting may be useful but may also cause strange behavior.

---Fills a rectangle in the grid with an arbitrary value. Can be used to write special values within the navigation grid.
---Only write special values or valid cell ids. Otherwise bad things may happen.
---@param cell_value integer
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.fill_grid(cell_value, x, y, col_span, row_span)
    col_span = col_span or 1
    row_span = row_span or 1
    if x < 1 or y < 1 or col_span < 1 or row_span < 1 then
        error("bad grid cell rectangle")
    end
    fill_grid(cell_value, x, y, x + col_span - 1, y + row_span - 1)
end

---Fills a rectangle in the grid with the last created cell index. That cell's grid position is then defined as the top-left corner of the rectangle.
---If this function isn't run after a make_cell call, then that cell can be tabbed to but not selected via navigating the grid.
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.grid_cell(x, y, col_span, row_span)
    keyboard_navigation.fill_grid(cell_index, x, y, col_span, row_span)
    cell_list[cell_index].x = x
    cell_list[cell_index].y = y
end

---Jumps to a specified cell id in the tab ordered table
local function jump_to_cell(new_selection)
    grid_x = cell_list[new_selection].x
    grid_y = cell_list[new_selection].y
    selected_cell = new_selection
end

---Returns the selection to the first in the tab order list.
local function jump_to_first()
    jump_to_cell(1)
end

---Returns the selection to the first in the tab order list.
local function jump_to_last()
    jump_to_cell(cell_index)
end

---Jumps 1 forward in the tab order. Wraps around if the end is reached.
local function jump_forward()
    if selected_cell >= cell_index then
        jump_to_first()
    else
        jump_to_cell(selected_cell + 1)
    end
end

---Jumps 1 backwards in the tab order. Wraps around if the beginning is reached.
local function jump_backwards()
    if selected_cell <= 1 then
        jump_to_last()
    else
        jump_to_cell(selected_cell - 1)
    end
end

---Jumps 1 page forwards in the tab order. Does not wrap.
local function page_forward()
    if selected_cell == cell_index then
        return
    end
    selected_cell = selected_cell + page_length
    if selected_cell > cell_index then
        selected_cell = cell_index
    end
    jump_to_cell(selected_cell)
end

---Jumps 1 page backwards in the tab order. Does not wrap.
local function page_backwards()
    if selected_cell == 1 then
        return
    end
    selected_cell = selected_cell - page_length
    if selected_cell < 1 then
        selected_cell = 1
    end
    jump_to_cell(selected_cell)
end

---The maximum amount of steps that navigation will take on the grid before giving up.
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
    error("couldn't find a border within a reasonable distance")
end

---Finds a point where wrapping can begin. The starting coordinate is checked.
---@param x integer Starting coordinate
---@param y integer Starting coordinate
---@param dx integer Walk step
---@param dy integer Walk step
---@return integer x Coordinate of encountered barrier
---@return integer y Coordinate of encountered barrier
local function find_wrapping_point(x, y, dx, dy)
    for _ = 1, MAX_SEARCH_DISTANCE do
        local encountered_value = get_grid_cell(x, y)
        if encountered_value < op_cell.nothing then
            return x, y
        end
        x = x + dx
        y = y + dy
    end
    error("couldn't find a barrier or wrap within a reasonable distance")
end

---Converts a directional keyboard action into a tab navigation
---@param action keyboard_action
local function tab_navigate(action)
    if action == kba.right or action == kba.down then
        jump_forward()
    elseif action == kba.left or action == kba.up then
        jump_backwards()
    else
        error("bad navigation action")
    end
end

---Converts a directional keyboard action into a page navigation
---@param action keyboard_action
local function page_navigate(action)
    if action == kba.right or action == kba.down then
        page_forward()
    elseif action == kba.left or action == kba.up then
        page_backwards()
    else
        error("bad navigation action")
    end
end

---Navigates the grid given a directional keyboard action
---@param action keyboard_action keyboard direction action number
---@return keyboard_action? redirected_action action number if navigation was redirected
local function navigate_grid(action)
    -- if nothing is selected or selection position is undefined, use tab ordering
    if selected_cell == 0 or not grid_x then
        tab_navigate(action)
        return nil
    end
    local original_selection = get_grid_cell(grid_x, grid_y)
    -- if the grid cursor is not on a proper cell, jump to the first cell
    if original_selection < 1 then
        jump_to_first()
        return nil
    end

    -- get the step direction
    local dx, dy, _
    if action == kba.right then
        dx, dy = 1, 0
    elseif action == kba.left then
        dx, dy = -1, 0
    elseif action == kba.down then
        dx, dy = 0, 1
    elseif action == kba.up then
        dx, dy = 0, -1
    else
        error("bad navigation action")
    end

    -- Search for the border of our current cell region
    local inside_x, inside_y, outside_x, outside_y, encountered_cell =
        find_border(original_selection, grid_x, grid_y, dx, dy)

    if encountered_cell == op_cell.nothing then
        -- encountered a nothing cell
        -- move the outside coordinates and change the encountered cell type so as if the nothing cells weren't there
        _, _, outside_x, outside_y, encountered_cell = find_border(op_cell.nothing, outside_x, outside_y, dx, dy)
    end

    if encountered_cell == op_cell.barrier then
        -- encountered a barrier
        grid_x, grid_y = inside_x, inside_y
    elseif encountered_cell == op_cell.wrap then
        -- locate a barrier in the opposite direction
        local barrier_x, barrier_y = find_wrapping_point(grid_x, grid_y, -dx, -dy)

        -- search for a border, starting at the barrier
        local wrap_x, wrap_y, wrap_encountered_cell
        _, _, wrap_x, wrap_y, wrap_encountered_cell = find_border(op_cell.nothing, barrier_x, barrier_y, dx, dy)

        if wrap_encountered_cell == original_selection then
            -- we found the same cell again
            -- wrapping behaves like a barrier in this case
            grid_x, grid_y = inside_x, inside_y
        else
            -- we found a different normal cell
            grid_x, grid_y = wrap_x, wrap_y
            selected_cell = wrap_encountered_cell
        end
    elseif encountered_cell == op_cell.tab then
        tab_navigate(action)
    elseif encountered_cell == op_cell.redirect then
        return action
    elseif encountered_cell == op_cell.page then
        page_navigate(action)
    else
        -- encountered a normal cell
        grid_x, grid_y = outside_x, outside_y
        selected_cell = encountered_cell
    end
    return nil
end

---Iterates through keyboard events and returns an action and whether it was a from a repeated keyboard input.
---Also updates the `holding_key` variable.
---@return keyboard_action? action Keyboard action. Nil if there was none.
---@return boolean is_repeat True if the returned keyboard action is a repeat
local function iterate_events()
    local action, is_repeat = nil, false

    for event in events.iterate("^key[pr]") do
        local name, key = event[1], event[2]

        if name == "keypressed" then
            is_repeat = event[4]
            if key == "right" or key == "left" or key == "down" or key == "up" then
                action = navigate_grid(key_to_action[key])
                if action then
                    holding_key = key
                end
            elseif key == "return" or key == "space" then
                holding_key = key
                if selected_cell == 0 then
                    if default_cell then
                        jump_to_cell(default_cell)
                        action = kba.activate
                    end
                else
                    action = kba.activate
                end
            elseif key == "escape" then
                if escape_cell then
                    holding_key = key
                    jump_to_cell(escape_cell)
                    action = kba.activate
                end

            -- The below keys do not trigger actions. They only navigate
            elseif key == "tab" then
                if love.keyboard.isDown("lshift", "rshift") then
                    jump_backwards()
                else
                    jump_forward()
                end
            elseif key == "home" then
                jump_to_first()
            elseif key == "end" then
                jump_to_last()
            elseif key == "pageup" then
                if selected_cell == 0 then
                    jump_to_last()
                else
                    page_backwards()
                end
            elseif key == "pagedown" then
                if selected_cell == 0 then
                    jump_to_first()
                else
                    page_forward()
                end
            end
        else -- name == "keyreleased"
            -- clear the holding_key field if that key was released.
            if key == holding_key then
                holding_key = nil
            end
        end
    end

    return action, is_repeat
end

---Run the navigation logic using keypressed events
function keyboard_navigation.evaluate()
    if cell_index < 1 then
        -- no cells were created
        return
    end

    local old_selection = selected_cell
    last_action, last_is_repeat = iterate_events()
    keyboard_navigation.selection_has_changed = old_selection ~= selected_cell

    -- reset everything
    erase_grid()
    cell_index = 0
    default_cell = nil
    escape_cell = nil
end

return keyboard_navigation
