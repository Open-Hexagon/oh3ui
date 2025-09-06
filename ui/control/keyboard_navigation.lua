local events = require("ui.events")
local bit = require("bit")
local bor, band = bit.bor, bit.band
local shared_data = require("ui.shared_data")
local control_data = shared_data.control
local control_method = shared_data.enums.control_method
local hover_off = require("ui.control.mouse_navigation").hover_off

local keyboard_navigation = {}

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

local page_length = 1

---Sets how many items forward or backwards to move when encountering the page op_cell or using the pageup or pagedown keys
---@param n integer
function keyboard_navigation.set_page_length(n)
    if n < 1 then
        error("page length cannot be less than 1")
    end
    page_length = n
end

--#region wrapping

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

--#endregion

--#region grid

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

--#endregion

---An ordered list of created cells
local cell_list = {}

local first_cell_id

---Holds the index of the last created cell.
---Only starts counting up after suppress_controls becomes false
---! Must accurately represent the length of the cell list
local last_cell_id = 0

---The index of the currently selected cell.
---0 indicates no selection.
---Usually survives between frames
local selected_cell_id = 0

---The index of the cell that gets activated if escape is pressed.
---nil means there was no cell set.
local escape_cell_id
---The index of the cell that gets activated if enter is pressed while nothing is selected
---nil means there was no cell set.
local default_cell_id

---The last performed keyboard action. Nil if there was no action.
---There only needs to be one since the keyboard can only interact with one thing at a time.
---@type keyboard_action?
local last_action
---The whether the last keyboard action is a repeated one
---There only needs to be one since the keyboard can only interact with one thing at a time.
local last_is_repeat

---The key name that is currently being held down. Only the latest pressed key is considered "held".
---@type string?
local held_action_key

---The secondary default cell that is kept track of when suppress_controls is true.
---Generally, this is the default cell of the layer below the top one.
local secondary_default

local function is_valid_cell_id(cell_id)
    if first_cell_id then
        return cell_id == 0 or (cell_id >= first_cell_id and cell_id <= last_cell_id)
    end
    return cell_id == 0
end

---Resets all data. Gets ready for the next frame
local function reset_all()
    erase_grid()
    first_cell_id = nil
    last_cell_id = 0
    control_data.current_cell_id = 0
    default_cell_id = nil
    escape_cell_id = nil
    secondary_default = nil
end

--#region Layer Transition stuff

---Restarts navigation for layer transitions
function keyboard_navigation.lt_restart()
    erase_grid()
    control_data.current_cell_id = 0
    first_cell_id = nil
    default_cell_id = nil
    escape_cell_id = nil
end

---This gets called when a layer transitions happens. Finds the best cell to select
function keyboard_navigation.lt_select_best_cell()
    -- clear this
    held_action_key = nil
    if default_cell_id then
        keyboard_navigation.jump_to_cell(default_cell_id)
    elseif secondary_default then
        selected_cell_id = secondary_default
        grid_x, grid_y = nil, nil
    else
        keyboard_navigation.jump_to_first()
    end
end

--#endregion

---Create a keyboard navigation cell which can be selected. The order in which these are called determines the tab order.
---@param mode?
---|"default" make this cell the default cell
---|"escape" make this cell the escape cell
---|"both" make this cell both the default and escape cell
---@return integer cell_id id number of this cell
function keyboard_navigation.make_cell(mode)
    last_cell_id = last_cell_id + 1

    if control_data.suppress_controls then
        if mode == "default" or mode == "both" then
            secondary_default = last_cell_id
        end
        return 0
    end

    if not first_cell_id then
        first_cell_id = last_cell_id
    end

    local cell = cell_list[last_cell_id]
    if cell then
        --erase old fields
        cell.x = nil
        cell.y = nil
        cell.text_input_state = nil
    else
        cell_list[last_cell_id] = {}
    end

    if mode == "escape" or mode == "both" then
        escape_cell_id = last_cell_id
    end

    if mode == "default" or mode == "both" then
        default_cell_id = last_cell_id
    end

    control_data.current_cell_id = last_cell_id

    return last_cell_id
end

---Informs keyboard navigation that a cell is meant for a text entry and thus certain actions should behave differently when interacting with this cell.
---If 0 is passed in as the cell id, it is silently ignored.
---@param cell_id integer
---@param state table
function keyboard_navigation.configure_cell_as_text_input(cell_id, state)
    if not is_valid_cell_id(cell_id) then
        error(string.format("bad cell id %d", cell_id))
    end
    if cell_id == 0 then
        return
    end
    local cell = cell_list[cell_id]
    cell.text_input_state = state
end

---Changes the currently recognized cell id.
---Can be used to revert the current cell back to a previously made cell.
---Setting the current cell to 0 prevents elements from being selected
---@param cell_id integer
function keyboard_navigation.change_to_cell(cell_id)
    if not is_valid_cell_id(cell_id) then
        error("bad cell id")
    end
    control_data.current_cell_id = cell_id
end

--#region Conditions

---You can use is_selected and get_action to get immediate values from the navigation.

---Returns true if the last created cell or specified cell is selected
---@param cell_id? integer
---@return boolean
---@nodiscard
function keyboard_navigation.is_selected(cell_id)
    cell_id = cell_id or control_data.current_cell_id
    if not is_valid_cell_id(cell_id) then
        error("bad cell id")
    end
    return cell_id > 0 and cell_id == selected_cell_id
end

---Returns the action of the last created cell
---@param cell_id? integer
---@return keyboard_action?
---@nodiscard
function keyboard_navigation.get_action(cell_id)
    if keyboard_navigation.is_selected(cell_id) then
        return last_action
    end
    return nil
end

---Returns the repeat state of the action on the last created cell
---@param cell_id? integer
---@return boolean?
---@nodiscard
function keyboard_navigation.is_repeat(cell_id)
    if keyboard_navigation.is_selected(cell_id) then
        return last_is_repeat
    end
    return nil
end

---Returns the holding action of the last created cell
---@param cell_id? integer
---@return keyboard_action?
---@nodiscard
function keyboard_navigation.get_holding(cell_id)
    if keyboard_navigation.is_selected(cell_id) then
        return key_to_action[held_action_key]
    end
    return nil
end

--#endregion

--#region Navigation Grid Creation

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

---Fills a rectangle in the grid with the current cell id and sets that cell's location.
---That cell's grid position is then defined as the top-left corner of the rectangle.
---If this function isn't run after a make_cell call, then that cell can be tabbed to but not selected via navigating the grid.
---A current cell id of 0 is silently ignored
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.grid_cell(x, y, col_span, row_span)
    local ci = control_data.current_cell_id
    if ci == 0 then
        return
    end
    keyboard_navigation.fill_grid(ci, x, y, col_span, row_span)
    cell_list[ci].x = x
    cell_list[ci].y = y
end

--#endregion

--#region Selection Operations

---Deselects any cell, returning keyboard navigation to its initial state.
function keyboard_navigation.deselect()
    selected_cell_id = 0
    grid_x, grid_y = nil, nil
end

---Moves the selection to a specified cell id in the tab ordered table.
---@param new_selection integer
function keyboard_navigation.jump_to_cell(new_selection)
    if not is_valid_cell_id(new_selection) then
        error(string.format("can't jump to cell %d", new_selection))
    end
    if new_selection == 0 then
        keyboard_navigation.deselect()
    else
        selected_cell_id = new_selection
        grid_x = cell_list[new_selection].x
        grid_y = cell_list[new_selection].y
    end
end

---Moves the selection to the first in the tab order list.
function keyboard_navigation.jump_to_first()
    keyboard_navigation.jump_to_cell(first_cell_id)
end

---Moves the selection to the first in the tab order list.
function keyboard_navigation.jump_to_last()
    keyboard_navigation.jump_to_cell(last_cell_id)
end

---Jumps 1 forward in the tab order. Wraps around if the end is reached.
function keyboard_navigation.jump_forward()
    if selected_cell_id >= last_cell_id or selected_cell_id == 0 then
        keyboard_navigation.jump_to_first()
    else
        keyboard_navigation.jump_to_cell(selected_cell_id + 1)
    end
end

---Jumps 1 backwards in the tab order. Wraps around if the beginning is reached.
function keyboard_navigation.jump_backwards()
    if selected_cell_id <= first_cell_id then
        keyboard_navigation.jump_to_last()
    else
        keyboard_navigation.jump_to_cell(selected_cell_id - 1)
    end
end

---Jumps 1 page forwards in the tab order. Does not wrap.
function keyboard_navigation.page_forward()
    if selected_cell_id == last_cell_id then
        return
    end
    selected_cell_id = selected_cell_id + page_length
    if selected_cell_id > last_cell_id then
        selected_cell_id = last_cell_id
    end
    keyboard_navigation.jump_to_cell(selected_cell_id)
end

---Jumps 1 page backwards in the tab order. Does not wrap.
function keyboard_navigation.page_backwards()
    if selected_cell_id == first_cell_id then
        return
    end
    selected_cell_id = selected_cell_id - page_length
    if selected_cell_id < first_cell_id then
        selected_cell_id = first_cell_id
    end
    keyboard_navigation.jump_to_cell(selected_cell_id)
end

--#endregion

--#region Grid Navigation

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
        keyboard_navigation.jump_forward()
    elseif action == kba.left or action == kba.up then
        keyboard_navigation.jump_backwards()
    else
        error("bad navigation action")
    end
end

---Converts a directional keyboard action into a page navigation
---@param action keyboard_action
local function page_navigate(action)
    if action == kba.right or action == kba.down then
        keyboard_navigation.page_forward()
    elseif action == kba.left or action == kba.up then
        keyboard_navigation.page_backwards()
    else
        error("bad navigation action")
    end
end

--#endregion

---Navigates the grid given a directional keyboard action
---@param action keyboard_action keyboard direction action number
---@return keyboard_action? redirected_action action number if navigation was redirected
local function navigate_grid(action)
    -- if nothing is selected or selection position is undefined, use tab ordering
    if selected_cell_id == 0 or not grid_x then
        tab_navigate(action)
        return nil
    end
    local original_selection = get_grid_cell(grid_x, grid_y)
    -- if the grid cursor is not on a proper cell, jump to the first cell
    if original_selection < 1 then
        keyboard_navigation.jump_to_first()
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
            selected_cell_id = wrap_encountered_cell
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
        selected_cell_id = encountered_cell
    end
    return nil
end

---Iterates through keyboard events and returns an action and whether it was a from a repeated keyboard input.
---Also updates the `holding_key` variable.
---@return keyboard_action? action Keyboard action. Nil if there was none.
---@return boolean is_repeat True if the returned keyboard action is a repeat
---@return table? typing_target If the text entry associated with this cell should be set as the typing target, this is its state table
---@return string? typing_action typing action if to perform when typing has started
local function iterate_events()
    local action, is_repeat = nil, false
    local typing_target, typing_action

    for event in events.iterate("^[tk]e") do
        local name, key = event[1], event[2]

        if name == "keypressed" then
            control_data.last_used_control_method = control_method.keyboard
            is_repeat = event[4]
            if key == "right" or key == "left" or key == "down" or key == "up" then
                -- only the arrow keys set the mouse to be invisible
                -- since if you're using the arrow keys you're probably going to keep on using the keyboard
                love.mouse.setVisible(false)
                hover_off()

                action = navigate_grid(key_to_action[key])

                ---held action is not asserted on repeated keypresses
                if action and not is_repeat then
                    held_action_key = key
                end
            elseif key == "return" or key == "space" then
                -- not spammable
                if not is_repeat then
                    held_action_key = key
                    if selected_cell_id == 0 then
                        if default_cell_id then
                            keyboard_navigation.jump_to_cell(default_cell_id)
                            action = kba.activate
                        end
                    else
                        action = kba.activate
                    end
                end
            elseif key == "escape" then
                -- not spammable
                if escape_cell_id and not is_repeat then
                    held_action_key = key
                    keyboard_navigation.jump_to_cell(escape_cell_id)
                    action = kba.activate
                end

            -- The below keys do not trigger actions. They only navigate
            elseif key == "tab" then
                if love.keyboard.isDown("lshift", "rshift") then
                    keyboard_navigation.jump_backwards()
                else
                    keyboard_navigation.jump_forward()
                end
            elseif key == "home" then
                keyboard_navigation.jump_to_first()
            elseif key == "end" then
                keyboard_navigation.jump_to_last()
            elseif key == "pageup" then
                if selected_cell_id == 0 then
                    keyboard_navigation.jump_to_last()
                else
                    keyboard_navigation.page_backwards()
                end
            elseif key == "pagedown" then
                if selected_cell_id == 0 then
                    keyboard_navigation.jump_to_first()
                else
                    keyboard_navigation.page_forward()
                end
            elseif key == "backspace" or key == "delete" then
                if selected_cell_id == 0 then
                    typing_target = default_cell_id and cell_list[default_cell_id].text_input_state
                else
                    typing_target = cell_list[selected_cell_id].text_input_state
                end
                if typing_target then
                    typing_action = key
                    break
                end
            end
        elseif name == "keyreleased" then
            control_data.last_used_control_method = control_method.keyboard
            -- clear the holding_key field if that key was released.
            if key == held_action_key then
                held_action_key = nil
            end
        elseif name == "textinput" then
            if selected_cell_id == 0 then
                typing_target = default_cell_id and cell_list[default_cell_id].text_input_state
                if typing_target then
                    keyboard_navigation.jump_to_cell(default_cell_id)
                    typing_action = key
                    break
                end
            else
                typing_target = cell_list[selected_cell_id].text_input_state
                if typing_target then
                    typing_action = key
                    break
                end
            end
        elseif name == "textedited" then
            -- I don't know what this one does.
        end
    end

    return action, is_repeat, typing_target, typing_action
end

---Run the navigation logic using keypressed events
---@return table? typing_target
---@return string? typing_action
function keyboard_navigation.evaluate()
    -- don't do anything if no cells were created
    if last_cell_id < 1 then
        keyboard_navigation.evaluate_without_events()
        return
    end

    local typing_target, typing_action

    local old_selection = selected_cell_id
    last_action, last_is_repeat, typing_target, typing_action = iterate_events()
    keyboard_navigation.selection_has_changed = old_selection ~= selected_cell_id

    reset_all()

    return typing_target, typing_action
end

---Does the usual evaluation cleanup without iterating through the events
function keyboard_navigation.evaluate_without_events()
    last_action, last_is_repeat = nil, false
    keyboard_navigation.selection_has_changed = false
    reset_all()
end

return keyboard_navigation
