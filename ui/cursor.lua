---The cursor represents a rectangular area on screen and is used as
---a tool for positioning and aligning ui elements.

local volatile_data = require("ui.shared_data").volatile
local draw_data = require("ui.draw_queue.draw_data")

local cursor = {}

---This table gets affected by translations so the area it represents will not always coincide with the cursor if a translation is in effect.
---Elements have to be literally placed in their final locations and not transformed by other means or else other position related functionality would break.

---This projected_placement table should only be used to measure distances from an element's placement location to the mouse.
---! IMPORTANT: This placement is a guess as to where the current placement is. It will be inaccurate if translations are edited afterwards.
---!            However, this usually isn't a problem when checking against mouse distances
cursor.projected_placement = {
    x = 0,
    y = 0,
    left = 0,
    top = 0,
    right = 0,
    bottom = 0,
}

cursor.placement = {
    x = 0,
    y = 0,
    left = 0,
    top = 0,
    right = 0,
    bottom = 0,
}

local projected_placement = cursor.projected_placement
local placement = cursor.placement

--#region edge calculations

---Returns edges from the current cursor parameters
---@param x number
---@param y number
---@param anchor_x number
---@param anchor_y number
---@param width number
---@param height number
---@return number
---@return number
---@return number
---@return number
local function get_edges(x, y, anchor_x, anchor_y, width, height)
    local left = x - anchor_x * width
    local top = y - anchor_y * height
    local right = x + (1 - anchor_x) * width
    local bottom = y + (1 - anchor_y) * height
    return left, top, right, bottom
end

local e_table = {}
local e_table_index = 0
local function unpack_e_table()
    return unpack(e_table, 1, e_table_index)
end

---This metatable lets you "swizzle" for the edges of the cursor.
---Examples:
---cursor.ltrb() returns the left, top, right, and bottom edges in that order.
---cursor.rrtb() returns the right, right, top, and bottom edges in that order.
---These are not affected by translations, use the placement table for that.
setmetatable(cursor, {
    __index = function(_, key)
        e_table_index = 0
        for c in string.gmatch(key, ".") do
            local v
            if c == "l" then
                v = cursor.x - cursor.anchor_x * cursor.width
            elseif c == "t" then
                v = cursor.y - cursor.anchor_y * cursor.height
            elseif c == "r" then
                v = cursor.x + (1 - cursor.anchor_x) * cursor.width
            elseif c == "b" then
                v = cursor.y + (1 - cursor.anchor_y) * cursor.height
            else
                error(string.format("`%s` is an invalid swizzling character", c))
            end
            e_table_index = e_table_index + 1
            e_table[e_table_index] = v
        end

        return unpack_e_table
    end,
})

--#endregion

local cursor_stack = volatile_data.cursor_stack
local translate_stack = volatile_data.translate_stack
local area_stack = volatile_data.area_stack

---Reset manual cursor to default values.
---By default cursor width and height are set to reflect the size of the screen.
---Explicit width and height can be passed in to override this behavior.
---@param desired_width number?
---@param desired_height number?
function cursor.reset(desired_width, desired_height)
    -- Position
    cursor.x = 0
    cursor.y = 0

    if desired_width and desired_height then
        cursor.width, cursor.height = desired_width, desired_height
    else
        cursor.width, cursor.height = love.graphics.inverseTransformPoint(love.graphics.getDimensions())
    end

    cursor.anchor_x = 0
    cursor.anchor_y = 0

    -- If true, elements that don't fit in the cursor will cause the cursor to reshape
    cursor.auto_reshape = true

    cursor.area_expansion_on()
end

--#region snapshotting

local CURSOR_INDEX_STEP = 7

---Push a snapshot of the cursor, saving its current state for later.
function cursor.push()
    local i = volatile_data.cursor_index + CURSOR_INDEX_STEP

    cursor_stack[i - 6] = cursor.x
    cursor_stack[i - 5] = cursor.y
    cursor_stack[i - 4] = cursor.anchor_x
    cursor_stack[i - 3] = cursor.anchor_y
    cursor_stack[i - 2] = cursor.width
    cursor_stack[i - 1] = cursor.height
    cursor_stack[i] = cursor.auto_reshape

    volatile_data.cursor_index = i
end

---Peek a snapshot of the cursor, returning it to the last pushed state without dropping it.
function cursor.peek()
    local i = volatile_data.cursor_index
    if i == volatile_data.cursor_base_index then
        error("cursor snapshot stack underflow", 2)
    end
    cursor.x, cursor.y, cursor.anchor_x, cursor.anchor_y, cursor.width, cursor.height, cursor.auto_reshape =
        unpack(cursor_stack, i - 6, i)
end

---Pop a snapshot of the cursor, returning it to the last pushed state.
function cursor.pop()
    cursor.peek()
    volatile_data.cursor_index = volatile_data.cursor_index - CURSOR_INDEX_STEP
end

---Drops the last snapshot of the cursor
function cursor.drop()
    if volatile_data.cursor_index == volatile_data.cursor_base_index then
        error("cursor snapshot stack underflow", 2)
    end
    volatile_data.cursor_index = volatile_data.cursor_index - CURSOR_INDEX_STEP
end

---Undos cursor reshaping for elements if cursor.auto_reshape is false. Requires a corresponding `cursor.push()`.
---Whatever the cursor's size is when this is called is considered the element's bounding box size when this is called.
---The cursor's location is always reverted to the popped cursor's snapshot (including anchors)
function cursor.do_auto_reshape()
    -- We only want the width and height to change.
    local width_new, height_new = cursor.width, cursor.height
    cursor.pop()
    if cursor.auto_reshape then
        cursor.width, cursor.height = width_new, height_new
    end
end

---Pop a snapshot and expand the current cursor to surround it.
---Does not change relative anchor locations.
---If the anchor is in the top-left then it will stay in the top-left after the operation, even if the cursor x, y had to move.
---@param peek? boolean If true, will not drop the top snapshot
function cursor.combine(peek)
    if volatile_data.cursor_index == volatile_data.cursor_base_index then
        error("cursor snapshot stack underflow", 2)
    end

    local i = volatile_data.cursor_index

    local new_left, new_top, new_right, new_bottom = get_edges(unpack(cursor_stack, i - 6, i - 1))
    local left, top, right, bottom =
        get_edges(cursor.x, cursor.y, cursor.anchor_x, cursor.anchor_y, cursor.width, cursor.height)

    left = math.min(new_left, left)
    top = math.min(new_top, top)
    right = math.max(new_right, right)
    bottom = math.max(new_bottom, bottom)

    cursor.width = right - left
    cursor.height = bottom - top
    cursor.x = left + cursor.anchor_x * cursor.width
    cursor.y = top + cursor.anchor_y * cursor.height

    if not peek then
        volatile_data.cursor_index = volatile_data.cursor_index - CURSOR_INDEX_STEP
    end
end

--#endregion

--#region layout and arrangement

---Changes the location of the cursor anchor without actually moving the cursor.
---If anchor_y isn't provided, then it will use the same value as anchor_x
---@param anchor_x number
---@param anchor_y number?
function cursor.change_anchor(anchor_x, anchor_y)
    anchor_y = anchor_y or anchor_x
    cursor.x = cursor.x + (anchor_x - cursor.anchor_x) * cursor.width
    cursor.y = cursor.y + (anchor_y - cursor.anchor_y) * cursor.height
    cursor.anchor_x = anchor_x
    cursor.anchor_y = anchor_y
end

---Offsets all cursor edges inwards by the same amount.
---@param d number
function cursor.inset(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(0.5, 0.5)
    cursor.width = cursor.width - 2 * d
    cursor.height = cursor.height - 2 * d
    cursor.change_anchor(ax, ay)
end

---Offsets all cursor edges outwards by the same amount.
---@param d number
function cursor.outset(d)
    cursor.inset(-d)
end

---Offsets the top and bottom cursor edges inwards by the same amount.
---@param d number
function cursor.v_squeeze(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(0.5, 0.5)
    cursor.height = cursor.height - 2 * d
    cursor.change_anchor(ax, ay)
end

---Offsets the top and bottom cursor edges outwards by the same amount.
---@param d number
function cursor.v_stretch(d)
    cursor.v_squeeze(-d)
end

---Offsets the left and right cursor edges inwards by the same amount.
---@param d number
function cursor.h_squeeze(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(0.5, 0.5)
    cursor.width = cursor.width - 2 * d
    cursor.change_anchor(ax, ay)
end

---Offsets the left and right cursor edges outwards by the same amount.
---@param d number
function cursor.h_stretch(d)
    cursor.h_squeeze(-d)
end

---Clips the left side of the cursor by d.
---@param d number
function cursor.clip_left(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(1, 1)
    cursor.width = cursor.width - d
    cursor.change_anchor(ax, ay)
end

---Clips the top side of the cursor by d.
---@param d number
function cursor.clip_top(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(1, 1)
    cursor.height = cursor.height - d
    cursor.change_anchor(ax, ay)
end

---Clips the right side of the cursor by d.
---@param d number
function cursor.clip_right(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(0, 0)
    cursor.width = cursor.width - d
    cursor.change_anchor(ax, ay)
end

---Clips the bottom side of the cursor by d.
---@param d number
function cursor.clip_bottom(d)
    local ax, ay = cursor.anchor_x, cursor.anchor_y
    cursor.change_anchor(0, 0)
    cursor.height = cursor.height - d
    cursor.change_anchor(ax, ay)
end

---Sets the cursor width to the width of the screen
function cursor.full_width()
    local _
    cursor.width, _ = love.graphics.inverseTransformPoint(love.graphics.getDimensions())
end

---Sets the cursor height to the height of the screen
function cursor.full_height()
    local _
    _, cursor.height = love.graphics.inverseTransformPoint(love.graphics.getDimensions())
end

---Sets the cursor width and height to that of the screen
function cursor.full_screen()
    cursor.width, cursor.height = love.graphics.inverseTransformPoint(love.graphics.getDimensions())
end

---Returns an iterator that returns n linspaced x coordinates derived from the current x-axis span of the cursor.
---An enumerate integer is also given. Goes from 1 to n.
---@param n integer
---@return fun():number?, integer?
function cursor.h_linspace(n)
    cursor.push()
    cursor.change_anchor(0)
    local base_x = cursor.x
    local step = cursor.width / (n - 1)
    cursor.pop()
    return coroutine.wrap(function()
        for i = 1, n do
            coroutine.yield(base_x + step * (i - 1), i)
        end
    end)
end

---Returns an iterator that returns n linspaced y coordinates derived from the current y-axis span of the cursor.
---An enumerate integer is also given. Goes from 1 to n.
---@param n integer
---@return fun():number?, integer?
function cursor.v_linspace(n)
    cursor.push()
    cursor.change_anchor(0)
    local base_y = cursor.y
    local step = cursor.height / (n - 1)
    cursor.pop()
    return coroutine.wrap(function()
        for i = 1, n do
            coroutine.yield(base_y + step * (i - 1), i)
        end
    end)
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from left to right with padding,
---while maintaining the cursor's current shape.
---@param n integer
---@param padding number?
function cursor.h_array(n, padding)
    padding = padding or 0
    for i = n - 1, 0, -1 do
        cursor.push()
        cursor_stack[volatile_data.cursor_index - 6] = cursor.x + (cursor.width + padding) * i
    end
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from top to bottom with padding,
---while maintaining the cursor's current shape.
---@param n integer
---@param padding number?
function cursor.v_array(n, padding)
    padding = padding or 0
    for i = n - 1, 0, -1 do
        cursor.push()
        cursor_stack[volatile_data.cursor_index - 5] = cursor.y + (cursor.height + padding) * i
    end
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from left to right with padding within the bounding box of the current cursor.
---Cursors take on the shape formed by horizontally subdividing the current cursor with padding.
---@param n integer number of sections to split into
---@param padding number? padding between sections
---@return integer n number of sections
---@return number section_width the width of each resulting section, not including padding
function cursor.h_split(n, padding)
    padding = padding or 0
    local section_width = (cursor.width - (n - 1) * padding) / n
    local left_edge = cursor.x - cursor.anchor_x * cursor.width

    for i = n - 1, 0, -1 do
        cursor.push()
        cursor_stack[volatile_data.cursor_index - 6] = left_edge
            + (section_width + padding) * i
            + section_width * cursor.anchor_x
        cursor_stack[volatile_data.cursor_index - 2] = section_width
    end

    return n, section_width
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from top to bottom with padding within the bounding box of the current cursor.
---Cursors take on the shape formed by vertically subdividing the current cursor with padding.
---@param n integer number of sections to split into
---@param padding number? padding between sections
---@return integer n number of sections
---@return number section_height the height of each resulting section, not including padding
function cursor.v_split(n, padding)
    padding = padding or 0
    local section_height = (cursor.height - (n - 1) * padding) / n
    local top_edge = cursor.y - cursor.anchor_y * cursor.height

    for i = n - 1, 0, -1 do
        cursor.push()
        cursor_stack[volatile_data.cursor_index - 5] = top_edge
            + (section_height + padding) * i
            + section_height * cursor.anchor_y
        cursor_stack[volatile_data.cursor_index - 1] = section_height
    end

    return n, section_height
end

---Move the cursor right by its own width
---@param padding number? defaults to 0
---@param times integer? defaults to 1
function cursor.shift_right(padding, times)
    cursor.x = cursor.x + (cursor.width + (padding or 0)) * (times or 1)
end

---Move the cursor left by its own width
---@param padding number? defaults to 0
---@param times integer? defaults to 1
function cursor.shift_left(padding, times)
    cursor.x = cursor.x - (cursor.width + (padding or 0)) * (times or 1)
end

---Move the cursor down by its own height
---@param padding number? defaults to 0
---@param times integer? defaults to 1
function cursor.shift_down(padding, times)
    cursor.y = cursor.y + (cursor.height + (padding or 0)) * (times or 1)
end

---Move the cursor up by its own height
---@param padding number? defaults to 0
---@param times integer? defaults to 1
function cursor.shift_up(padding, times)
    cursor.y = cursor.y - (cursor.height + (padding or 0)) * (times or 1)
end

---Returns true if the cursor has a non-positive width or height
---@return boolean
function cursor.is_degenerate()
    return cursor.width <= 0 or cursor.height <= 0
end

--#endregion

--#region translations

---Apply a translation to the cursor. Translations stack.
---This translations can be edited later, but if it is, the projected_placement table will be inaccurate.
---In this case, the first time a translation is applied, it should be a reasonable guess as to where the translation should be.
---@param x number
---@param y number
---@return integer translate_id
function cursor.push_translation(x, y)
    local index = volatile_data.translate_index
    local prev_x, prev_y = translate_stack[index - 1], translate_stack[index]
    index = index + 2

    translate_stack[index - 1] = prev_x + x
    translate_stack[index] = prev_y + y

    volatile_data.translate_index = index

    return draw_data.make_push_translation(x, y)
end

---Removes the last applied translation
function cursor.pop_translation()
    if volatile_data.translate_index == volatile_data.translate_base_index then
        error("no more translations to remove")
    end
    volatile_data.translate_index = volatile_data.translate_index - 2

    draw_data.make_pop_translation()
end

cursor.edit_translation = draw_data.edit_translation
cursor.get_translation = draw_data.get_translation

--#endregion

--#region areas
-- An area is a generic rectangular bounding box for elements.
-- After an area is started, any new elements that are created will expand the area.
-- Areas can be stacked, newly created elements only affect the topmost area.
-- When an area is ended, it's representation is put into the cursor.
-- Ending an area expands the area below, unless the no_propagate is true when calling finish_area
-- Areas depend only on the cursor location. They are not affected by translations

local do_area_expansion = true

---expands a specified area
---@param area table
---@param left number
---@param top number
---@param right number
---@param bottom number
local function expand_area(area, left, top, right, bottom)
    if area and do_area_expansion then
        area.left = area.left == nil and left or math.min(area.left, left)
        area.top = area.top == nil and top or math.min(area.top, top)
        area.right = area.right == nil and right or math.max(area.right, right)
        area.bottom = area.bottom == nil and bottom or math.max(area.bottom, bottom)
    end
end

---Begins a new area.
function cursor.start_area()
    -- Add a new area to the stack
    volatile_data.area_index = volatile_data.area_index + 1
    local new_area = area_stack[volatile_data.area_index]
    if new_area then
        new_area.left = nil
        new_area.top = nil
        new_area.right = nil
        new_area.bottom = nil
    else
        area_stack[volatile_data.area_index] = {}
    end
end

---Puts the current area representation into the cursor.
---If the area contains no objects, this function does nothing.
---@return boolean empty_area true if the finished area had no elements
function cursor.put_area()
    local this_area = area_stack[volatile_data.area_index]
    -- There might be nothing to put if no placements have been made
    if this_area.left then
        cursor.width = this_area.right - this_area.left
        cursor.height = this_area.bottom - this_area.top
        cursor.x = this_area.left + cursor.anchor_x * cursor.width
        cursor.y = this_area.top + cursor.anchor_y * cursor.height
        return false
    end
    return true
end

---Ends the last started area.
---The cursor will be set to that area.
---@param no_propagate boolean? if true, doesn't propagate this area to the below area
---@return boolean exists true if the finished area has at least one element
function cursor.finish_area(no_propagate)
    if volatile_data.area_index == volatile_data.area_base_index then
        error("no areas to end")
    end

    local exists = false
    local this_area = area_stack[volatile_data.area_index]
    -- There might be nothing to put if no placements have been made
    if this_area.left then
        cursor.width = this_area.right - this_area.left
        cursor.height = this_area.bottom - this_area.top
        cursor.x = this_area.left + cursor.anchor_x * cursor.width
        cursor.y = this_area.top + cursor.anchor_y * cursor.height

        if not no_propagate then
            expand_area(
                area_stack[volatile_data.area_index - 1],
                get_edges(cursor.x, cursor.y, cursor.anchor_x, cursor.anchor_y, cursor.width, cursor.height)
            )
        end
        exists = true
    end

    volatile_data.area_index = volatile_data.area_index - 1

    return exists
end

function cursor.area_expansion_off()
    do_area_expansion = false
end

function cursor.area_expansion_on()
    do_area_expansion = true
end

--#endregion

---Places the current cursor down. This will update both the last_placement and projected_placement tables.
---Translations will be applied to ONLY the projected_placement table.
---Desired width and height are for elements that don't fit the cursor.
---Passing desired width and height will reshape the cursor.
---Placing a cursor will also expand areas.
---@param desired_width number? if provided, the placement will use this instead of cursor.width
---@param desired_height number? if provided, the placement will use this instead of cursor.height
function cursor.place(desired_width, desired_height)
    local width, height = desired_width or cursor.width, desired_height or cursor.height
    local dx, dy = translate_stack[volatile_data.translate_index - 1], translate_stack[volatile_data.translate_index]
    local left, top, right, bottom = get_edges(cursor.x, cursor.y, cursor.anchor_x, cursor.anchor_y, width, height)

    -- update projected_placement
    projected_placement.x = cursor.x + dx
    projected_placement.y = cursor.y + dy
    projected_placement.left = left + dx
    projected_placement.top = top + dy
    projected_placement.right = right + dx
    projected_placement.bottom = bottom + dy

    -- expand the current area
    expand_area(area_stack[volatile_data.area_index], left, top, right, bottom)

    -- update placement
    placement.x = cursor.x
    placement.y = cursor.y
    placement.left = left
    placement.top = top
    placement.right = right
    placement.bottom = bottom

    -- reshape the cursor
    cursor.width, cursor.height = width, height
end

return cursor
