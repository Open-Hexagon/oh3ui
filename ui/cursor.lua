---The cursor represents a rectangular area on screen and is used as
---a tool for positioning and aligning ui elements.

---Note: parameters that are contained within tables are not saved in snapshots
local cursor = {}

---Edge output table mainly to be used by elements.
---This table gets affected by translations so the area it represents will not always coincide with the cursor if a translation is in affect.
---Elements have to be literally placed in their final locations and not transformed by other means
---or else other position related functionality would break.
---Use this if you want to check against a the literal location of a placed element. Such as when comparing against the mouse position.
cursor.placement = {
    left = 0,
    top = 0,
    right = 0,
    bottom = 0,
    -- the coordinate points are also affected
    x = 0,
    y = 0,
}

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

local snapshot_stack = {}
local snapshot_index = 0 -- index of the last pushed snapshot

local translate_stack = { { 0, 0 } } -- the do-nothing translation is always here
local translate_index = 1 -- index of the last pushed translation

local area_stack = {}
local area_index = 0 -- index of the last started area

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
end

-- first cursor setup
cursor.reset()

---Should be run at the end of a frame to clean up all stacks
function cursor.finish()
    if snapshot_index ~= 0 then
        print("warning: cursor stack was not empty")
        snapshot_index = 0
    end
    if translate_index ~= 1 then
        print("warning: translation stack was not empty")
        translate_index = 1
    end
end

--#region snapshotting

---Push a snapshot of the cursor, saving its current state for later.
function cursor.push()
    snapshot_index = snapshot_index + 1

    local new_snapshot = snapshot_stack[snapshot_index]
    if not new_snapshot then
        new_snapshot = {}
        snapshot_stack[snapshot_index] = new_snapshot
    end

    new_snapshot.x = cursor.x
    new_snapshot.y = cursor.y
    new_snapshot.width = cursor.width
    new_snapshot.height = cursor.height
    new_snapshot.anchor_x = cursor.anchor_x
    new_snapshot.anchor_y = cursor.anchor_y
    new_snapshot.auto_reshape = cursor.auto_reshape
end

---Peek a snapshot of the cursor, returning it to the last pushed state without dropping it.
function cursor.peek()
    if snapshot_index == 0 then
        error("cursor snapshot stack underflow", 2)
    end
    for k, v in pairs(snapshot_stack[snapshot_index]) do
        cursor[k] = v
    end
end

---Pop a snapshot of the cursor, returning it to the last pushed state.
function cursor.pop()
    cursor.peek()
    snapshot_index = snapshot_index - 1
end

---Drops the last snapshot of the cursor
function cursor.drop()
    if snapshot_index == 0 then
        error("cursor snapshot stack underflow", 2)
    end
    snapshot_index = snapshot_index - 1
end

---Undos cursor reshaping for elements if cursor.auto_reshape is false. Requires a corresponding `cursor.push()`.
function cursor.do_auto_reshape()
    -- We only want the width and height to change.
    local width_new, height_new = cursor.width, cursor.height
    cursor.pop()
    if cursor.auto_reshape then
        cursor.width, cursor.height = width_new, height_new
    end
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
        snapshot_stack[snapshot_index].x = cursor.x + (cursor.width + padding) * i
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
        snapshot_stack[snapshot_index].y = cursor.y + (cursor.height + padding) * i
    end
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from left to right with padding within the bounding box of the current cursor.
---Cursors take on the shape formed by horizontally subdividing the current cursor with padding.
---@param n integer number of sections to split into
---@param padding number? padding between sections
---@return number section_width the width of each resulting section, not including padding
function cursor.h_split(n, padding)
    padding = padding or 0
    local section_width = (cursor.width - (n - 1) * padding) / n
    local left_edge = cursor.x - cursor.anchor_x * cursor.width

    for i = n - 1, 0, -1 do
        cursor.push()
        snapshot_stack[snapshot_index].x = left_edge + (section_width + padding) * i + section_width * cursor.anchor_x
        snapshot_stack[snapshot_index].width = section_width
    end

    return section_width
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from top to bottom with padding within the bounding box of the current cursor.
---Cursors take on the shape formed by vertically subdividing the current cursor with padding.
---@param n integer number of sections to split into
---@param padding number? padding between sections
---@return number section_height the height of each resulting section, not including padding
function cursor.v_split(n, padding)
    padding = padding or 0
    local section_height = (cursor.height - (n - 1) * padding) / n
    local top_edge = cursor.y - cursor.anchor_y * cursor.height

    for i = n - 1, 0, -1 do
        cursor.push()
        snapshot_stack[snapshot_index].y = top_edge + (section_height + padding) * i + section_height * cursor.anchor_y
        snapshot_stack[snapshot_index].height = section_height
    end

    return section_height
end

---Pop a snapshot and expand the current cursor to surround it.
---Does not change relative anchor locations.
---If the anchor is in the top-left then it will stay in the top-left after the operation, even if the cursor x, y had to move.
---@param peek? boolean If true, will not drop the top snapshot
function cursor.combine(peek)
    if snapshot_index == 0 then
        error("cursor snapshot stack underflow", 2)
    end

    local s = snapshot_stack[snapshot_index]

    local new_left, new_top, new_right, new_bottom = get_edges(s.x, s.y, s.anchor_x, s.anchor_y, s.width, s.height)
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
        snapshot_index = snapshot_index - 1
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
---Only affects the edge output table.
---@param x number
---@param y number
function cursor.apply_translation(x, y)
    local prev_x, prev_y = unpack(translate_stack[translate_index])
    translate_index = translate_index + 1

    if translate_stack[translate_index] then
        translate_stack[translate_index][1] = prev_x + x
        translate_stack[translate_index][2] = prev_y + y
    else
        translate_stack[translate_index] = { prev_x + x, prev_y + y }
    end
end

---Removes the last applied translation
function cursor.remove_translation()
    if translate_index == 1 then
        error("no more translations to remove")
    end
    translate_index = translate_index - 1
end

--#endregion

--#region areas
-- An area is a generic rectangular bounding box for elements.
-- After an area is started, any new elements that are created will expand the area.
-- Areas can be stacked, newly created elements only affect the topmost area.
-- When an area is ended, it's representation is put into the cursor.
-- Ending an area does not expand the area below. Use a cursor.place immediately after an area is finished to do that.

---expands a specified area
---@param area table
---@param left number
---@param top number
---@param right number
---@param bottom number
local function expand_area(area, left, top, right, bottom)
    if area then
        area.left = area.left == nil and left or math.min(area.left, left)
        area.top = area.top == nil and top or math.min(area.top, top)
        area.right = area.right == nil and right or math.max(area.right, right)
        area.bottom = area.bottom == nil and bottom or math.max(area.bottom, bottom)
    end
end

---Begins a new area.
function cursor.begin_area()
    -- Add a new area to the stack
    area_index = area_index + 1
    local new_area = area_stack[area_index]
    if new_area then
        new_area.left = nil
        new_area.top = nil
        new_area.right = nil
        new_area.bottom = nil
    else
        area_stack[area_index] = {}
    end
end

---Puts the current area representation into the cursor.
---If the area contains no objects, this function does nothing.
function cursor.put_area()
    local this_area = area_stack[area_index]
    -- There might be nothing to put if no placements have been made
    if this_area.left then
        cursor.width = this_area.right - this_area.left
        cursor.height = this_area.bottom - this_area.top
        cursor.x = this_area.left + cursor.anchor_x * cursor.width
        cursor.y = this_area.top + cursor.anchor_y * cursor.height
    end
end

---Ends the last started area.
---The cursor will be set to that area.
function cursor.end_area()
    if area_index == 0 then
        error("no areas to end")
    end
    cursor.put_area()
    area_index = area_index - 1
end

--#endregion

---Places the current cursor down. This will update the cursor edge output table as well as expand areas.
---Translations will be applied to the edge output table.
---Desired width and height are typically used by elements when their contents don't fit the cursor exactly.
---Passing desired width and height will reshape the cursor.
---@param desired_width number? if provided, the placement will use this instead of cursor.width
---@param desired_height number? if provided, the placement will use this instead of cursor.height
function cursor.place(desired_width, desired_height)
    local width, height = desired_width or cursor.width, desired_height or cursor.height

    -- Apply translation
    placement.x = cursor.x + translate_stack[translate_index][1]
    placement.y = cursor.y + translate_stack[translate_index][2]

    -- Update edges
    placement.left, placement.top, placement.right, placement.bottom =
        get_edges(placement.x, placement.y, cursor.anchor_x, cursor.anchor_y, width, height)

    -- Expand the current area
    expand_area(area_stack[area_index], get_edges(cursor.x, cursor.y, cursor.anchor_x, cursor.anchor_y, width, height))

    -- reshape the cursor
    cursor.width, cursor.height = width, height
end

return cursor
