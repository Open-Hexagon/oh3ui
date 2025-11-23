local events = require("ui.events")
local bit = require("bit")
local bor, band = bit.bor, bit.band
local disable_intersection_checks = require("ui.control.sensor").disable_intersection_checks
local control_backend = require("ui.control.backend")
local is_suppressed = require("ui.suppress").is_suppressed
local layer_status = require("ui.layer.status")

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
    tab = 0x02, -- if grid_x is out of bounds, navigation will see tab op cells
    redirect = 0x04, -- if grid_x is out of bounds, navigation will see redirect op cells
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
---@type integer?
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
---@nodiscard
local function get_grid_cell(x, y)
    if x < 1 or x > grid_width then
        -- x coordinate exceeds grid size
        if band(wrapping_mode, wmode.horizontal) ~= 0 then
            return op_cell.wrap
        elseif band(wrapping_mode, wmode.tab) ~= 0 then
            return op_cell.tab
        elseif band(wrapping_mode, wmode.redirect) ~= 0 then
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

---Gets the current grid location. Nil if there is none.
---This usually isn't very useful unless you're debugging something.
---@return integer?
---@return integer?
---@nodiscard
function keyboard_navigation.get_grid_location()
    return grid_x, grid_y
end

---Sets the current grid location.
---@param x integer
---@param y integer
function keyboard_navigation.set_grid_location(x, y)
    grid_x, grid_y = x, y
end

--#endregion

---An ordered list of created cells
local cell_x = {}
local cell_y = {}
local cell_text_input_state = {}
local cell_keepout = {}

---The cell id that is used to check for selection and actions
---The cell id 0 will never be assigned normally
---@type integer
local current_cell_id = 0

---Holds the index of the last created cell.
local last_cell_id = 0

---The index of the currently selected cell.
---0 indicates no selection.
---Usually survives between frames
local selected_cell_id = 0

---The id of the cell that gets activated if escape is pressed.
---nil means there was no cell set.
local escape_cell_id

---The id of the cell that gets activated if enter is pressed while nothing is selected
---nil means there was no cell set.
local default_cell_id

---The id of the cell that's globally accessible for typing. This is stronger than the default cell if it also has a text input.
---nil means there was no cell set.
local global_typing_cell_id

---The id of the first cell that has a actual grid position.
---nil means no cells exist on the grid
local first_gridded_cell_id

---The id of the last cell that has a actual grid position.
---nil means no cells exist on the grid
local last_gridded_cell_id

--[[
    Action behavior:

    A = some action
    _ = no action or false
    T = true
    P = press event
    p = repeated press event
    . = OS key-repeat delay
    R = release event

    (Not to scale. Illustrative purposes only)
    events           P......p p p p p p p p p pR
    held_action     __AAAAAAAAAAAAAAAAAAAAAAAAAA__
    last_action     __A______A_A_A_A_A_A_A_A_A_A__
    last_is_repeat  _________T_T_T_T_T_T_T_T_T_T__
                    frames -->
]]

---The last performed keyboard action. Nil if there was no action.
---There only needs to be one since the keyboard can only interact with one thing at a time.
---@type keyboard_action?
local last_action

---The whether the last keyboard action is a repeated one
---There only needs to be one since the keyboard can only interact with one thing at a time.
---@type boolean
local last_is_repeat = false

---The action that is currently being held down. Only the latest made action is considered "held".
---The held action is not reasserted on repeated keypresses.
---@type keyboard_action?
local held_action

---Forces for 1 frame to say that the selection has changed.
---Used to trigger a scroll view request when a layer transition happens
local force_selection_has_changed = false

local selection_has_changed = false

local function is_valid_cell_id(cell_id)
    return cell_id >= 0 and cell_id <= last_cell_id
end

---Gets the currently selected cell id
---@return integer
---@nodiscard
function keyboard_navigation.get_selected_cell_id()
    return selected_cell_id
end

---Gets the id of the last cell that has a actual grid position
---@return integer
---@nodiscard
function keyboard_navigation.get_last_gridded_cell_id()
    return last_gridded_cell_id
end

function keyboard_navigation.has_selection_just_changed()
    return selection_has_changed
end

--#region Cell Controls

---Create a keyboard navigation cell which can be selected. The order in which these are called determines the tab order.
---@param mode?
---|"default" make this cell the default cell
---|"escape" make this cell the escape cell
---|"both" make this cell both the default and escape cell
---@return integer cell_id id number of this cell
function keyboard_navigation.make_cell(mode)
    if not layer_status.is_current_layer_active() then
        return 0
    end

    last_cell_id = last_cell_id + 1

    -- erase old fields
    cell_x[last_cell_id] = nil
    cell_y[last_cell_id] = nil
    cell_text_input_state[last_cell_id] = nil
    cell_keepout[last_cell_id] = is_suppressed()

    if mode == "default" or mode == "both" then
        default_cell_id = last_cell_id
    end

    if mode == "escape" or mode == "both" then
        escape_cell_id = last_cell_id
    end

    current_cell_id = last_cell_id

    return last_cell_id
end

---Changes the currently recognized cell id.
---Can be used to revert the current cell back to a previously made cell.
---Setting the current cell to 0 prevents elements from being selected
---@param cell_id integer
function keyboard_navigation.set_current_cell_id(cell_id)
    if not is_valid_cell_id(cell_id) then
        error("bad cell id")
    end
    current_cell_id = cell_id
end

---Gets the current cell id
---@return integer
---@nodiscard
function keyboard_navigation.get_current_cell_id()
    return current_cell_id
end

--#endregion

--#region Conditions

---Returns true if the last created cell or specified cell is selected
---@param cell_id? integer
---@return boolean
---@nodiscard
function keyboard_navigation.is_selected(cell_id)
    cell_id = cell_id or current_cell_id
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
        return held_action
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

---Fills a rectangle in the grid with the latest created cell id and sets that cell's location. (The latest created cell id is not necessarily the current cell id!)
---That cell's grid position is then defined as the top-left corner of the rectangle.
---If this function isn't run after a make_cell call, then that cell can be tabbed to but not selected via navigating the grid.
---@param x integer
---@param y integer
---@param col_span? integer
---@param row_span? integer
function keyboard_navigation.grid_cell(x, y, col_span, row_span)
    if last_cell_id == 0 or is_suppressed() then
        return
    end

    if not first_gridded_cell_id then
        first_gridded_cell_id = last_cell_id
    end

    last_gridded_cell_id = last_cell_id

    cell_x[last_cell_id] = x
    cell_y[last_cell_id] = y
    keyboard_navigation.fill_grid(last_cell_id, x, y, col_span, row_span)
end

--#endregion

--#region Selection Operations

---Deselects any cell, returning keyboard navigation to its initial state.
local function deselect()
    selected_cell_id = 0
    grid_x, grid_y = nil, nil
end
keyboard_navigation.deselect = deselect

---Moves the selection to a specified cell id in the tab ordered table.
---Will jump to the cell even if it's in a keepout zone.
---@param new_selection integer
local function jump_to_cell(new_selection)
    if not is_valid_cell_id(new_selection) then
        error(string.format("can't jump to cell %d", new_selection))
    end
    if new_selection == 0 then
        deselect()
    else
        selected_cell_id = new_selection
        grid_x = cell_x[new_selection]
        grid_y = cell_y[new_selection]
    end
end
keyboard_navigation.jump_to_cell = jump_to_cell

---Moves the selection to the first in the tab order list.
local function jump_to_first()
    jump_to_cell(1)
end

---Moves the selection to the first in the tab order list.
local function jump_to_last()
    jump_to_cell(last_cell_id)
end

---Jumps 1 forward in the tab order. Wraps around if the end is reached.
local function tab_forward()
    if selected_cell_id >= last_cell_id then
        jump_to_first()
    else
        repeat -- make sure we're not in a keepout zone
            selected_cell_id = selected_cell_id + 1
        until not cell_keepout[selected_cell_id]
        jump_to_cell(selected_cell_id)
    end
end
keyboard_navigation.tab_forward = tab_forward

---Jumps 1 backwards in the tab order. Wraps around if the beginning is reached.
local function tab_backwards()
    if selected_cell_id <= 1 then
        jump_to_last()
    else
        repeat -- make sure we're not in a keepout zone
            selected_cell_id = selected_cell_id - 1
        until not cell_keepout[selected_cell_id]
        jump_to_cell(selected_cell_id)
    end
end
keyboard_navigation.tab_backwards = tab_backwards

---Jumps 1 page forwards in the tab order. Does not wrap.
local function page_forward()
    if selected_cell_id == last_cell_id then
        return
    end
    selected_cell_id = selected_cell_id + page_length
    if selected_cell_id > last_cell_id then
        selected_cell_id = last_cell_id
    end
    jump_to_cell(selected_cell_id)
end

---Jumps 1 page backwards in the tab order. Does not wrap.
local function page_backwards()
    if selected_cell_id == 1 then
        return
    end
    selected_cell_id = selected_cell_id - page_length
    if selected_cell_id < 1 then
        selected_cell_id = 1
    end
    jump_to_cell(selected_cell_id)
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
        tab_forward()
    elseif action == kba.left or action == kba.up then
        tab_backwards()
    else
        -- luacov: disable
        error("bad navigation action")
        -- luacov: enable
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
        -- luacov: disable
        error("bad navigation action")
        -- luacov: enable
    end
end

local function enter_grid(action)
    if action == kba.right or action == kba.down then
        jump_to_cell(first_gridded_cell_id)
    elseif action == kba.left or action == kba.up then
        jump_to_cell(last_gridded_cell_id)
    else
        -- luacov: disable
        error("bad navigation action")
        -- luacov: enable
    end
end

--#endregion

---Navigates the grid given a directional keyboard action
---@param action keyboard_action keyboard direction action number
---@return keyboard_action? redirected_action action number if navigation was redirected
local function navigate_grid(action)
    -- if nothing is selected and something is in the grid then go to the first one
    if selected_cell_id == 0 then
        if first_gridded_cell_id then
            enter_grid(action)
        end
        return nil
    end

    -- if something is selected but it doesn't have a grid position then use tab navigation
    if not grid_x then
        tab_navigate(action)
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
        -- luacov: disable
        error("bad navigation action")
        -- luacov: enable
    end

    local original_selection = get_grid_cell(grid_x, grid_y)
    if original_selection < 0 then
        -- if the grid cursor is not on a proper cell, jump to the first cell as fallback
        jump_to_first()
        return nil
    end

    -- Search for the border of our current cell region
    local inside_x, inside_y, outside_x, outside_y, encountered_cell =
        find_border(original_selection, grid_x, grid_y, dx, dy)

    if original_selection == 0 then
        -- Our grid position started in the void
        if encountered_cell < 1 then
            -- we found an op_cell, jump to the first cell as fallback
            jump_to_first()
        else
            -- we found a normal cell
            grid_x, grid_y = outside_x, outside_y
            selected_cell_id = encountered_cell
        end
        return nil
    end

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
            control_backend.last_used_control_method = "keyboard"
            is_repeat = event[4]
            if key == "right" or key == "left" or key == "down" or key == "up" then
                -- only the arrow keys set the mouse to be invisible
                -- since if you're using the arrow keys you're probably going to keep on using the keyboard
                love.mouse.setVisible(false)
                disable_intersection_checks()

                action = navigate_grid(key_to_action[key])

                -- held action is not asserted on repeated keypresses
                if action and not is_repeat then
                    held_action = action
                end
            elseif key == "return" or key == "space" then
                -- not spammable
                if not is_repeat then
                    held_action = key_to_action[key]
                    if selected_cell_id == 0 then
                        if default_cell_id then
                            jump_to_cell(default_cell_id)
                            action = kba.activate
                        end
                    else
                        action = kba.activate
                    end
                end
            elseif key == "escape" then
                if
                    not is_repeat -- not spammable
                    and escape_cell_id
                then
                    held_action = key_to_action[key]
                    jump_to_cell(escape_cell_id)
                    action = kba.activate
                end

            -- The below keys do not trigger actions. They only navigate
            elseif key == "tab" then
                if love.keyboard.isDown("lshift", "rshift") then
                    tab_backwards()
                else
                    tab_forward()
                end
            elseif key == "home" then
                jump_to_first()
            elseif key == "end" then
                jump_to_last()
            elseif key == "pageup" then
                if selected_cell_id == 0 then
                    jump_to_last()
                else
                    page_backwards()
                end
            elseif key == "pagedown" then
                if selected_cell_id == 0 then
                    jump_to_first()
                else
                    page_forward()
                end
            elseif key == "backspace" or key == "delete" then
                if selected_cell_id == 0 then
                    typing_target = default_cell_id and cell_text_input_state[default_cell_id]
                else
                    typing_target = cell_text_input_state[selected_cell_id]
                end
                if typing_target then
                    typing_action = key
                    break
                end
            end
        elseif name == "keyreleased" then
            control_backend.last_used_control_method = "keyboard"
            -- clear the holding_key field if that key was released.
            if key_to_action[key] == held_action then
                held_action = nil
            end
        elseif name == "textinput" then
            typing_target = cell_text_input_state[selected_cell_id]
            if typing_target then
                typing_action = key
                break
            end

            if global_typing_cell_id then
                -- blacklist the space key from activating global typing since it's also used to activate elements,
                -- but only if the selected cell is different from the global typing cell
                -- but not including cell 0
                if key ~= " " or global_typing_cell_id == selected_cell_id or selected_cell_id == 0 then
                    typing_target = cell_text_input_state[global_typing_cell_id]
                    jump_to_cell(global_typing_cell_id)
                    typing_action = key
                    break
                end
            elseif selected_cell_id == 0 then
                typing_target = default_cell_id and cell_text_input_state[default_cell_id]
                if typing_target then
                    jump_to_cell(default_cell_id)
                    typing_action = key
                    break
                end
            end

            -- elseif name == "textedited" then
            -- I don't know what this one does.
        end
    end

    return action, is_repeat, typing_target, typing_action
end

---Run the navigation logic using keypressed events
---@return table? typing_target
---@return string? typing_action
---@nodiscard
function keyboard_navigation.evaluate()
    -- don't do anything if no cells were created
    if last_cell_id < 1 then
        keyboard_navigation.evaluate_without_events()
        return
    end

    local typing_target, typing_action

    local old_selection = selected_cell_id
    last_action, last_is_repeat, typing_target, typing_action = iterate_events()

    if force_selection_has_changed then
        selection_has_changed = true
        force_selection_has_changed = false
    else
        selection_has_changed = old_selection ~= selected_cell_id
    end

    return typing_target, typing_action
end

---Does the usual evaluation cleanup without iterating through the events
function keyboard_navigation.evaluate_without_events()
    last_action, last_is_repeat = nil, false
    held_action = nil

    if force_selection_has_changed then
        selection_has_changed = true
        force_selection_has_changed = false
    else
        selection_has_changed = false
    end
end

---Resets all data. Gets ready for the next frame
function keyboard_navigation.reset()
    erase_grid()
    last_cell_id = 0
    current_cell_id = 0
    escape_cell_id = nil
    default_cell_id = nil
    global_typing_cell_id = nil
    first_gridded_cell_id = nil
    last_gridded_cell_id = nil
end

---This only gets called when a layer transitions happens. Finds the best cell to select.
function keyboard_navigation.finish_layer_transition()
    held_action = nil
    force_selection_has_changed = true
    if default_cell_id then
        jump_to_cell(default_cell_id)
    else
        jump_to_first()
    end
end

---Informs keyboard navigation that a cell is meant for a text entry and thus certain actions should behave differently when interacting with this cell.
---If 0 is passed in as the cell id, it is silently ignored.
---@param cell_id integer
---@param state table
---@param global boolean?
function keyboard_navigation.configure_cell_as_text_input(cell_id, state, global)
    if not is_valid_cell_id(cell_id) then
        error(string.format("bad cell id %d", cell_id))
    end
    if cell_id == 0 or not layer_status.is_current_layer_active() then
        return
    end
    cell_text_input_state[cell_id] = state

    if global then
        global_typing_cell_id = cell_id
    end
end

return keyboard_navigation
