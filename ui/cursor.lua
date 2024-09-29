---The cursor represents a rectangular area on screen and is used as
---a tool for positioning and aligning ui elements.
---Also checks for mouse intersection.
---For checking mouse buttons, see mouse.lua

local json = require("extlibs.json.json")

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
    mouse_intersect = {
        enter = false,
        exit = false,
        hovering = false,
    },
}

local anchor = cursor.anchor
local edge = cursor.edge
local mouse_intersect = cursor.mouse_intersect

---Reset manual cursor to default values
function cursor.reset()
    -- Position
    cursor.x = 0
    cursor.y = 0
    cursor.width = 0
    cursor.height = 0
    cursor.anchor_x = anchor.LEFT
    cursor.anchor_y = anchor.TOP
    ---if true, when the cursor is placed with a desired size that is different from the
    ---current cursor, the cursor will be reshaped to enclose the placement
    cursor.reshape_on_placement = false

    -- text
    cursor.font = "assets/OpenSquare.ttf"
    cursor.font_size = 32
    cursor.text_align = "left"
    cursor.wrap_text = false -- if true, the cursor width will be used to wrap text.

    -- * do not write to the following fields manually

    -- edges
    edge.left = 0
    edge.top = 0
    edge.right = 0
    edge.bottom = 0

    -- mouse intersection
    mouse_intersect.enter = false
    mouse_intersect.exit = false
    mouse_intersect.hovering = false
end

-- first cursor setup
cursor.reset()

--#region snapshotting

-- Cursor snapshots
local snapshots = {}
local index = 0

---Push a snapshot of the cursor, saving its current state for later.
function cursor.push()
    index = index + 1
    if not snapshots[index] then
        snapshots[index] = {}
    end
    for k, v in pairs(cursor) do
        local t = type(v)
        -- Only certain types should be saved
        if t == "number" or t == "string" or t == "boolean" then
            snapshots[index][k] = v
        end
    end
end

---Pop a snapshot of the cursor, returning it to the last pushed state.
function cursor.pop()
    if index == 0 then
        error("cursor stack underflow")
    end
    for k, v in pairs(snapshots[index]) do
        cursor[k] = v
    end
    index = index - 1
end

---Should be run at the end of a frame
function cursor.finish()
    if index ~= 0 then
        print("warning: cursor stack was not empty")
        index = 0
    end
end

--#endregion

--#region layout and arrangement

---Changes the location of the cursor anchor without actually moving the cursor.
---@param anchor_x number
---@param anchor_y number
function cursor.change_anchor(anchor_x, anchor_y)
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

---Returns an iterator function that will move the cursor in a grid pattern.
---The anchor will be moved to the top-left of the cursor on each iteration.
---@param cols integer number of columns
---@param rows integer number of rows
---@param padding integer? spacing between columns and rows
---@param flip_horizontal boolean? iterate right to left
---@param flip_vertical boolean? iterate from bottom to top
---@return fun():integer?, integer?
function cursor.grid(cols, rows, padding, flip_horizontal, flip_vertical)
    ---Get the base location and size so grid geometry is not
    ---lost even if the cursor is modified between iterations.
    cursor.change_anchor(anchor.LEFT, anchor.TOP)
    local width, height = cursor.width, cursor.height
    local base_x, base_y = cursor.x, cursor.y

    padding = padding or 0
    local dir_x = flip_horizontal and -1 or 1
    local dir_y = flip_vertical and -1 or 1

    return coroutine.wrap(function()
        for y = 0, (rows - 1) * dir_y, dir_y do
            for x = 0, (cols - 1) * dir_x, dir_x do
                cursor.x = base_x + (width + padding) * x
                cursor.y = base_y + (height + padding) * y
                cursor.width = width
                cursor.height = height
                cursor.anchor_x = anchor.LEFT
                cursor.anchor_y = anchor.TOP
                coroutine.yield(x, y)
            end
        end
    end)
end

---Returns an iterator that moves the cursor in a grid pattern
---formed by subdividing the current cursor into rows and columns.
---The anchor will be moved to the top-left of the cursor on each iteration.
---@param cols integer number of columns
---@param rows integer number of rows
---@param padding number spacing between columns and rows
---@return fun():integer?, integer?
function cursor.subdivide(cols, rows, padding)
    cursor.change_anchor(anchor.LEFT, anchor.TOP)
    cursor.width = (cursor.width - (cols - 1) * padding) / cols
    cursor.height = (cursor.height - (rows - 1) * padding) / rows
    return cursor.grid(cols, rows, padding)
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
---@param desired_width number? if provided, the placement will use this instead of cursor.width
---@param desired_height number? if provided, the placement will use this instead of cursor.height
---@param enclose_override boolean? overrides the cursor.reshape_on_placement field
function cursor.place(desired_width, desired_height, enclose_override)
    local width, height = desired_width or cursor.width, desired_height or cursor.height

    -- Update edges
    edge.left = cursor.x - cursor.anchor_x * width
    edge.top = cursor.y - cursor.anchor_y * height
    edge.right = cursor.x + (1 - cursor.anchor_x) * width
    edge.bottom = cursor.y + (1 - cursor.anchor_y) * height

    -- Expand the current area
    local area = require("ui.area")
    area.expand(edge.left, edge.top, edge.right, edge.bottom)

    -- Enclose the placed area if needed
    if enclose_override or cursor.reshape_on_placement then
        cursor.width, cursor.height = width, height
    end
end

---Check and update whether the mouse is intersecting the cursor (i.e. the mouse is hovering the cursor).
---Also detects if the mouse just entered or exited the cursor area.
function cursor.update_mouse_intersect()
    local mouse_pos = require("ui.interaction.mouse")

    local hovering_before = mouse_pos.prev_x >= edge.left
        and mouse_pos.prev_x < edge.right
        and mouse_pos.prev_y >= edge.top
        and mouse_pos.prev_y < edge.bottom

    local hovering_now = mouse_pos.x >= edge.left
        and mouse_pos.x < edge.right
        and mouse_pos.y >= edge.top
        and mouse_pos.y < edge.bottom

    mouse_intersect.hovering = hovering_now
    mouse_intersect.enter = hovering_now and not hovering_before
    mouse_intersect.exit = not hovering_now and hovering_before
end

---Cache of fonts based on file used and size
local font_cache = {}

---get the currently used font object
---@param scale_adjusted boolean?
---@return love.Font
function cursor.get_font(scale_adjusted)
    local file = cursor.font
    local size = cursor.font_size
    if scale_adjusted then
        size = size * math.floor(require("ui").scale * 100) / 100
    end
    font_cache[file] = font_cache[file] or {}
    local font = font_cache[file][size]
    if not font then
        font = love.graphics.newFont(file, size)
        font:setFilter("nearest", "nearest")
        font_cache[file][size] = font
    end
    return font
end

local icon_font_ids = {}

---get a table of icon id keys with the actual string values for the icons in the current font
---@return unknown?
function cursor.get_icon_font_ids()
    local file = cursor.font:gsub("(.*)%..+", "%1.json")
    local ids = icon_font_ids[file]
    if not ids then
        if not love.filesystem.exists(file) then
            return
        end
        ids = json.decode(love.filesystem.read(file))
        for key, value in pairs(ids) do
            ids[key] = love.data.decode("string", "hex", value)
        end
        icon_font_ids[file] = ids
    end
    return ids
end

return cursor
