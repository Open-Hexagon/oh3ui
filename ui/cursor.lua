---The cursor represents a rectangular area on screen and is used as
---a tool for positioning and aligning ui elements.
---For checking whether the mouse is currently intersecting the cursor, see sensor/init.lua.
-- Note: parameters that are contained within tables are not saved in snapshots
local cursor = {
    -- anchor constants
    anchor = {
        TOP = 0,
        LEFT = 0,
        BOTTOM = 1,
        RIGHT = 1,
        CENTER = 0.5,
    },

    -- edge output table
    edge = {
        left = 0,
        top = 0,
        right = 0,
        bottom = 0,
    },
}

local anchor = cursor.anchor
local edge = cursor.edge

---Reset manual cursor to default values
function cursor.reset()
    -- Position
    cursor.x = 0
    cursor.y = 0

    -- setting width and height to the screen size.
    -- this is nice when used with cursor subdividing to easily divide the screen.
    cursor.width, cursor.height = love.graphics.inverseTransformPoint(love.graphics.getDimensions())

    cursor.anchor_x = anchor.LEFT
    cursor.anchor_y = anchor.TOP

    -- If true, elements that don't fit in the cursor will cause the cursor to reshape
    cursor.auto_reshape = true

    -- * do not write to the following fields manually

    -- edges
    edge.left = 0
    edge.top = 0
    edge.right = 0
    edge.bottom = 0
end

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

-- first cursor setup
cursor.reset()

--#region snapshotting

-- Cursor snapshots
local snapshots = {}
local index = 0 -- index of the last pushed snapshot

---Should be run at the end of a frame to clean up the snapshot stack
function cursor.finish()
    if index ~= 0 then
        print("warning: cursor stack was not empty")
        index = 0
    end
end

---Push a snapshot of the cursor, saving its current state for later.
function cursor.push()
    index = index + 1

    local new_snapshot = snapshots[index]
    if not new_snapshot then
        new_snapshot = {}
        snapshots[index] = new_snapshot
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
    if index == 0 then
        error("cursor stack underflow")
    end
    for k, v in pairs(snapshots[index]) do
        cursor[k] = v
    end
end

---Pop a snapshot of the cursor, returning it to the last pushed state.
function cursor.pop()
    cursor.peek()
    index = index - 1
end

---Drops the last snapshot of the cursor
function cursor.drop()
    if index == 0 then
        error("cursor stack underflow")
    end
    index = index - 1
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
        snapshots[index].x = cursor.x + (cursor.width + padding) * i
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
        snapshots[index].y = cursor.y + (cursor.height + padding) * i
    end
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from left to right with padding within the bounding box of the current cursor.
---Cursors take on the shape formed by horizontally subdividing the current cursor with padding.
---@param n integer
---@param padding number?
function cursor.h_split(n, padding)
    padding = padding or 0
    local section_width = (cursor.width - (n - 1) * padding) / n
    local left_edge = cursor.x - cursor.anchor_x * cursor.width

    for i = n - 1, 0, -1 do
        cursor.push()
        snapshots[index].x = left_edge + (section_width + padding) * i + section_width * cursor.anchor_x
        snapshots[index].width = section_width
    end
end

---Pushes n snapshots to the stack, such that when popping them,
---the cursor will move from top to bottom with padding within the bounding box of the current cursor.
---Cursors take on the shape formed by vertically subdividing the current cursor with padding.
---@param n integer
---@param padding number?
function cursor.v_split(n, padding)
    padding = padding or 0

    local section_height = (cursor.height - (n - 1) * padding) / n
    local top_edge = cursor.y - cursor.anchor_y * cursor.height

    for i = n - 1, 0, -1 do
        cursor.push()
        snapshots[index].y = top_edge + (section_height + padding) * i + section_height * cursor.anchor_y
        snapshots[index].height = section_height
    end
end

---Pop a snapshot and expand the current cursor to surround it.
---Does not change relative anchor locations.
---If the anchor is in the top-left then it will stay in the top-left after the operation, even if the cursor x, y had to move.
function cursor.combine()
    if index == 0 then
        error("cursor stack underflow")
    end

    local s = snapshots[index]

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

    index = index - 1
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
    cursor.change_anchor(anchor.CENTER, anchor.CENTER)
    cursor.width = cursor.width - 2 * d
    cursor.height = cursor.height - 2 * d
    cursor.change_anchor(ax, ay)
end

---Offsets all cursor edges outwards by the same amount.
---@param d number
function cursor.outset(d)
    cursor.inset(-d)
end

---Returns an iterator that returns linspaced x coordinates derived from the current x-axis span of the cursor.
---An enumerate integer is also given. Goes from 1 to n.
---@param n integer
---@return fun():number?, integer?
function cursor.x_linspace(n)
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

---Returns an iterator that returns linspaced y coordinates derived from the current y-axis span of the cursor.
---An enumerate integer is also given. Goes from 1 to n.
---@param n integer
---@return fun():number?, integer?
function cursor.y_linspace(n)
    cursor.push()
    cursor.change_anchor(0)
    local base_y = cursor.y
    local step = cursor.height / (n - 1)
    cursor.pop()
    return coroutine.wrap(function()
        for i = 0, n - 1 do
            coroutine.yield(base_y + step * i)
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

--#endregion

---Places the current cursor down. This will update the cursor edges output table (left, top, right, bottom) as well as expand areas.
---Desired width and height are typically used by elements when their contents don't fit the cursor exactly.
---Passing desired width and height will reshape the cursor.
---@param desired_width number? if provided, the placement will use this instead of cursor.width
---@param desired_height number? if provided, the placement will use this instead of cursor.height
function cursor.place(desired_width, desired_height)
    local width, height = desired_width or cursor.width, desired_height or cursor.height

    -- Update edges
    edge.left, edge.top, edge.right, edge.bottom =
        get_edges(cursor.x, cursor.y, cursor.anchor_x, cursor.anchor_y, width, height)

    -- Expand the current area
    local area = require("ui.area")
    area.expand(edge.left, edge.top, edge.right, edge.bottom)

    -- reshape the cursor
    cursor.width, cursor.height = width, height
end

return cursor
