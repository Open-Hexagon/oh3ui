---Handles a queue of draw operations. All queued drawed operations will be executed at the end of the frame.
---These draw operations are lower-level bare commands and do not interact with the cursor at all.
---For nicer functions that implicitly use the cursor and color themes, see primitive.lua

local scissor_stack = require("ui.draw_queue.scissor_stack")
local text_cache = require("ui.text.cache")
local draw_queue = {}

local op_ids = {
    rectangle = 0,
    polygon = 1,
    push_scissor = 2,
    pop_scissor = 3,
    text = 4,
    call_group = 5,
}

-- A list of groups
local groups = {}
-- Holds the index of the current group. Equal to 1 after initialization. Group 1 is the root group.
local current_group_index = 0
-- Holds the index of the last created group. Equal to 1 after initialization.
local last_group_index = 0

---Pushes an operation to the current group. The first value should be an operation id.
---This operation id can be nil which will cause the operation to be ignored.
---@param ... unknown
local function push_operation(...)
    local current_group = groups[current_group_index]
    local queue = current_group.op_list

    local slot_index

    if current_group.take_reservation then
        -- take a reservation
        slot_index = current_group.take_reservation
        current_group.take_reservation = nil
    else
        current_group.op_index = current_group.op_index + 1
        slot_index = current_group.op_index
    end

    queue[slot_index] = queue[slot_index] or {}
    for i = 1, math.max(select("#", ...), #queue[slot_index]) do
        queue[slot_index][i] = select(i, ...)
    end
end

function draw_queue.begin_group()
    -- save the current group index so we can come back
    local return_index = current_group_index

    -- set up a new group
    last_group_index = last_group_index + 1
    local new_group = groups[last_group_index]

    if new_group then
        -- reset the new group
        new_group.op_index = 0
        new_group.reserve_index = 0
        new_group.return_index = return_index
        new_group.take_reservation = nil
    else
        -- this new group has never been made before
        new_group = {
            -- The list of draw operations in this group
            op_list = {},
            -- Holds the index of the last item in the op_list. Equals 0 if it's empty.
            op_index = 0,
            -- the reservation stack
            reservations = {},
            -- Holds the index of the topmost item in the reservation stack. Equals 0 if it's empty.
            reserve_index = 0,
            -- Holds the index of the reservation that the next draw operation should take.
            take_reservation = nil,
            -- The index of the group to return to when this group is ended. If it's 0, then it's the root group.
            return_index = return_index,
        }
        groups[last_group_index] = new_group
    end

    current_group_index = last_group_index
end

function draw_queue.end_group()
    -- save where we returned from
    local from_group_index = current_group_index

    local current_group = groups[current_group_index]

    -- warn if not all reservations were taken from this group
    if current_group.reserve_index ~= 0 or current_group.take_reservation then
        print(string.format("warning: not all reservations were taken in group %d after ending", from_group_index))
    end

    -- get were we're returning to
    local return_group_index = current_group.return_index

    if return_group_index == 0 then
        error("no more groups to end!")
    end

    -- return and push an operation to call the group we just ended
    current_group_index = return_group_index
    push_operation(op_ids.call_group, from_group_index)
end

---resets the group list to its initial state
local function reset_groups()
    current_group_index = 0
    last_group_index = 0
    draw_queue.begin_group()
end

-- do initial group setup
reset_groups()

---Reserves the next, single draw operation to be filled in later.
---This reservation is pushed to the reservations stack.
function draw_queue.reserve()
    push_operation()
    local current_group = groups[current_group_index]
    current_group.reserve_index = current_group.reserve_index + 1
    current_group.reservations[current_group.reserve_index] = current_group.op_index
end

---The next executed draw operation will fill in the last single reserved slot.
---The reservation on the top of the reservations stack is popped.
---Only works on a single draw operation. Use groups to have multiple operations take the place of one reservation. 
function draw_queue.take_last_reservation()
    local current_group = groups[current_group_index]
    if current_group.reserve_index == 0 then
        error(string.format("no more reservations to take in group %d", current_group_index))
    end
    current_group.take_reservation = current_group.reservations[current_group.reserve_index]
    current_group.reserve_index = current_group.reserve_index - 1
end

---Add a no-operation to the queue.
---Can be used to pop the reservation stack without adding any operation.
function draw_queue.nop()
    push_operation()
end

---queue pushing a scissor rectangle onto the scissor stack
---@param left number
---@param top number
---@param right number
---@param bottom number
function draw_queue.push_scissor(left, top, right, bottom)
    push_operation(op_ids.push_scissor, left, top, right, bottom)
end

---queue poping a scissor rectangle from the scissor stack
function draw_queue.pop_scissor()
    push_operation(op_ids.pop_scissor)
end

--#region functions that actually draw things

---add a rectangle to the queue
---@param mode love.DrawMode
---@param left number
---@param top number
---@param right number
---@param bottom number
---@param color table
---@param rx number?
---@param ry number?
function draw_queue.rectangle(mode, left, top, right, bottom, color, rx, ry)
    rx, ry = rx or 0, ry or 0
    push_operation(op_ids.rectangle, mode, left, top, right, bottom, rx, ry, unpack(color))
end

-- ---add a rectangle to the queue
-- ---@param left number
-- ---@param top number
-- ---@param right number
-- ---@param bottom number
-- ---@param color table
-- ---@param rx number?
-- ---@param ry number?
-- function draw_queue.outline(left, top, right, bottom, color, rx, ry)
--     local x1, y1 = love.graphics.transformPoint(left, top)
--     local x2, y2 = love.graphics.transformPoint(right, bottom)
--     rx, ry = love.graphics.transformPoint(rx or 0, ry or 0)
--     push_operation(op_ids.outline, "line", x1, y1, x2, y2, rx, ry, unpack(color))
-- end

local polygon_data = {}

---add a polygon to the queue
---@param mode string
---@param vertices table
---@param color table
function draw_queue.polygon(mode, vertices, color)
    for i = 1, #vertices, 2 do
        polygon_data[i], polygon_data[i + 1] = vertices[i], vertices[i + 1]
    end
    for i = 1, 4 do
        polygon_data[#vertices + i] = color[i]
    end
    push_operation(op_ids.polygon, mode, unpack(polygon_data, 1, #vertices + 4))
end

---add text to the queue
---@param text string
---@param font love.Font
---@param x number
---@param y number
---@param color table
---@param wraplimit number?
---@param align love.AlignMode?
function draw_queue.text(text, font, x, y, color, wraplimit, align)
    local text_object = text_cache.get(font, text, wraplimit or math.huge, align or "left")
    push_operation(op_ids.text, text_object, x, y, unpack(color))
end

--#endregion

---Executes all draw operations. Uses recursion to handle groups
---@param group_index integer the group to run
local function run_draw_operations(group_index)
    local current_group = groups[group_index]
    for i = 1, current_group.op_index do
        local item = current_group.op_list[i]
        local id = item[1]
        -- id may be nil if a placeholder was left in / nothing was appended
        if id then
            if id == op_ids.rectangle then
                local mode, x1, y1, x2, y2, rx, ry, r, g, b, a = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
            elseif id == op_ids.polygon then
                local len = #item
                love.graphics.setColor(unpack(item, len - 3, len))
                love.graphics.polygon(item[2], unpack(item, 3, len - 4))
            elseif id == op_ids.text then
                local text_object, x, y, r, g, b, a = unpack(item, 2)
                love.graphics.setColor(r, g, b, a)
                love.graphics.draw(text_object, x, y)
            elseif id == op_ids.push_scissor then
                local x1, y1, x2, y2 = unpack(item, 2)
                scissor_stack.push(x1, y1, x2 - x1, y2 - y1)
            elseif id == op_ids.pop_scissor then
                scissor_stack.pop()
            elseif id == op_ids.call_group then
                run_draw_operations(item[2])
            end
        end
    end
end

---Execute all queued commands.
---This will also reset everything related to the queue
function draw_queue.draw()
    -- ensure all groups are ended
    if current_group_index ~= 1 then
        error("not all groups were ended")
    end

    -- warn if not all reservations were taken
    local current_group = groups[current_group_index]
    if current_group.reserve_index ~= 0 or current_group.take_reservation then
        print(string.format("warning: not all reservations were taken in root group 1 before drawing"))
    end

    run_draw_operations(1)
    reset_groups()

    -- Ensure the scissor stack is empty
    scissor_stack.finish()
end

return draw_queue
