---The cursor represents a rectangular area on screen and is used as
---a tool for positioning and aligning ui elements.
---Also checks for mouse intersection.
---For checking mouse buttons, see mouse.lua

-- Cursor snapshots
local snapshots = {}
local index = 0

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

    -- output tables
    edge = {},
    mouse = {},
}

local anchor = cursor.anchor
local edge = cursor.edge
local mouse = cursor.mouse

---Reset manual cursor to default values
function cursor.reset()
    -- Position
    cursor.x = 0
    cursor.y = 0
    cursor.width = 0
    cursor.height = 0
    cursor.anchor_x = anchor.LEFT
    cursor.anchor_y = anchor.TOP

    -- text
    cursor.font = "assets/OpenSquare.ttf"
    cursor.font_size = 32
    cursor.text_wraplimit = math.huge
    cursor.text_align = "left"
    -- allow increasing element size automatically if too small
    cursor.allow_automatic_resizing = true

    -- * do not write to the following fields manually

    -- edges
    edge.left = 0
    edge.top = 0
    edge.right = 0
    edge.bottom = 0

    -- mouse intersection
    mouse.enter = false
    mouse.exit = false
    mouse.hovering = false

    -- mouse clicks
    cursor.clicked.right = false
    cursor.clicked.left = false
    cursor.clicked.middle = false
end

-- first cursor setup
cursor.reset()

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
---@param nx integer number of iterations along the x direction
---@param ny integer number of iterations along the y direction
---@param padding integer? spacing between iterations
---@param flip_horizontal boolean? iterate right to left
---@param flip_vertical boolean? iterate from bottom to top
---@return fun():integer?, integer?
function cursor.grid(nx, ny, padding, flip_horizontal, flip_vertical)
    ---Get the base location and size so grid geometry is not
    ---lost even if the cursor is modified between iterations.
    cursor.change_anchor(anchor.LEFT, anchor.TOP)
    local width = cursor.width
    local height = cursor.height
    local base_x = cursor.x
    local base_y = cursor.y

    padding = padding or 0
    local dir_x = flip_horizontal and -1 or 1
    local dir_y = flip_vertical and -1 or 1

    return coroutine.wrap(function()
        for y = 0, (ny - 1) * dir_y, dir_y do
            for x = 0, (nx - 1) * dir_x, dir_x do
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

---Places the current cursor down. This will update the cursor edges output table (left, top, right, bottom) as well as expand areas.
---All elements should implicitly place the cursor.
function cursor.place()
    -- Update edges
    edge.left = cursor.x - cursor.anchor_x * cursor.width
    edge.top = cursor.y - cursor.anchor_y * cursor.height
    edge.right = cursor.x + (1 - cursor.anchor_x) * cursor.width
    edge.bottom = cursor.y + (1 - cursor.anchor_y) * cursor.height

    -- Expand the current area
    local area = require("ui.area")
    area.expand(edge.left, edge.top, edge.right, edge.bottom)
end

---Check and update whether the mouse is intersecting the cursor (i.e. the mouse is hovering the cursor).
---Also detects if the mouse just entered or exited the cursor area.
function cursor.update_mouse_intersect()
    local mouse = require("ui.interaction.mouse")

    local hovering_before = mouse.prev_x >= edge.left
        and mouse.prev_x <= edge.right
        and mouse.prev_y >= edge.top
        and mouse.prev_y <= edge.bottom

    local hovering_now = mouse.x >= edge.left
        and mouse.x <= edge.right
        and mouse.y >= edge.top
        and mouse.y <= edge.bottom

    mouse.hovering = hovering_now
    mouse.enter = hovering_now and not hovering_before
    mouse.exit = not hovering_now and hovering_before
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

return cursor
