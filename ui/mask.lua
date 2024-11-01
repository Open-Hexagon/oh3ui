-- Handles masking of ui elements
local cursor = require("ui.cursor")
local edge = cursor.edge
-- local draw_queue = require("ui.draw_queue")
local aligned_rectangle_intersection = require("ui.extmath").aligned_rectangle_intersection

local mask = {}

-- A stack of mask snapshots
local snapshot = {}
local index = 0

---Mask everything outside of the cursor. Further draw operations will not affect masked areas.
function mask.push()
    cursor.place()

    local x1, y1, x2, y2
    if index == 0 then
        -- no previous masks
        x1, y1, x2, y2 = edge.left, edge.top, edge.right, edge.bottom
    else
        -- intersect with the last mask
        x1, y1, x2, y2 =
            aligned_rectangle_intersection(edge.left, edge.top, edge.right, edge.bottom, unpack(snapshot[index]))

        if not x1 then
            -- no intersection, this should cull out everything
            x1, y1, x2, y2 = 0, 0, 0, 0
        end
    end

    ---to appease the type checker
    ---@cast x1 number
    ---@cast y1 number
    ---@cast x2 number
    ---@cast y2 number

    -- get transformed points
    local tx1, ty1 = love.graphics.transformPoint(x1, y1)
    local tx2, ty2 = love.graphics.transformPoint(x2, y2)

    -- save a snapshot of this mask
    index = index + 1
    if snapshot[index] then
        snapshot[index][1], snapshot[index][2], snapshot[index][3], snapshot[index][4] = x1, y1, x2, y2
        snapshot[index][5], snapshot[index][6], snapshot[index][7], snapshot[index][8] = tx1, ty1, tx2, ty2
    else
        snapshot[index] = { x1, y1, x2, y2, tx1, ty1, tx2, ty2 }
    end

    -- add to the draw queue
    draw_queue.call(love.graphics.setScissor, tx1, ty1, tx2 - tx1, ty2 - ty1)
end

---Removes the last pushed mask
function mask.pop()
    if index == 0 then
        error("scissor stack underflow")
    end
    index = index - 1
    if index == 0 then
        draw_queue.call(love.graphics.setScissor)
    else
        local tx1, ty1, tx2, ty2 = unpack(snapshot[index], 5)
        draw_queue.call(love.graphics.setScissor, tx1, ty1, tx2 - tx1, ty2 - ty1)
    end
end

---Gets the bounds of the intersection of all masks
---@return number?, number?, number?, number?
function mask.get_bounds()
    if index > 0 then
        return unpack(snapshot[index], 1, 4)
    else
        return nil
    end
end

---Outputs a warning and clears the stack if it was not empty.
function mask.finish()
    if index ~= 0 then
        print("warning: scissor stack was not empty")
        index = 0
    end
end

return mask
