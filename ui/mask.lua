local cursor = require("ui.cursor")
local draw_queue = require("ui.draw_queue")

local mask = {}

---Hooks for mask changes.
local on_mask_change_hooks = {}
local on_mask_change_index = 0

---Register a nullary function to be called whenever the mask gets modified.
---@param fn function
function mask.register_on_mask_change_hook(fn)
    on_mask_change_index = on_mask_change_index + 1
    on_mask_change_hooks[on_mask_change_index] = fn
end

local function run_mask_change_hooks()
    for i = 1, on_mask_change_index do
        on_mask_change_hooks[i]()
    end
end

-- A stack of scissor snapshots
local snapshot = {}
local index = 0

---Mask everything outside of the cursor. Further draw operations will not affect masked areas.
---Mouse interaction is disabled in masked areas.
---Applying a mask does not place the cursor!
---Make sure to pop the mask when you're done!
function mask.push()
    -- Even though we're not drawing anything yet, we can use the scissor's behavior to do bounds checking.
    -- Manually calculate scissor location since we don't want to a full cursor place.
    local tx, ty = cursor.get_translation()
    local x, y, width, height =
        cursor.x - cursor.anchor_x * cursor.width + tx,
        cursor.y - cursor.anchor_y * cursor.height + ty,
        cursor.width,
        cursor.height
    love.graphics.intersectScissor(x, y, width, height)

    x, y, width, height = love.graphics.getScissor()
    draw_queue.set_scissor(x, y, width, height)

    -- save a snapshot of what the scissor is like now
    index = index + 1
    if snapshot[index] then
        snapshot[index][1], snapshot[index][2], snapshot[index][3], snapshot[index][4] = x, y, width, height
    else
        snapshot[index] = { x, y, width, height }
    end

    run_mask_change_hooks()
end

---Removes the last applied mask.
function mask.pop()
    if index == 0 then
        error("scissor stack underflow")
    end

    index = index - 1
    if index == 0 then
        love.graphics.setScissor()
    else
        love.graphics.setScissor(unpack(snapshot[index]))
    end

    draw_queue.set_scissor(love.graphics.getScissor())

    run_mask_change_hooks()
end

---@return number?
---@return number?
---@return number?
---@return number?
function mask.get()
    local x, y, width, height = love.graphics.getScissor()
    if x then
        return x, y, x + width, y + height
    end
    return nil, nil, nil, nil
end

---Guards against sloppy mask management.
function mask.finish()
    if index ~= 0 then
        print("warning: the mask stack was not empty")
        love.graphics.setScissor()
        index = 0
    end
end

return mask
