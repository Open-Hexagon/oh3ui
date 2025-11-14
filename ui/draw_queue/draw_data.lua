local draw_operation = require("ui.draw_queue.draw_operation")
local bit = require("bit")
local band, bor = bit.band, bit.bor

local ID_POS = 1

local draw_data = {}
local draw_data_is_blocked = true

---List of placements. Always in order.
local placement_list = {}
---Index of the last item in the placement list
local placement_index = 0

---List of draw operations. Can be created out of order.
local draw_list = {}
---Hold the index of the last pushed draw operation
local draw_index = 0

---List of reservations
local res_list = {}
---Holds the index of the last created reservation
local res_index = 0
---Contains the reservation index that the next operation will use, nil otherwise
local take_reservation_id = nil

local as_overlay = false

--#region placements and translations

---adds a placement
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return integer placement_id
function draw_data.make_placement(left, top, right, bottom)
    placement_index = placement_index + 5

    placement_list[placement_index - 4] = "placement"
    placement_list[placement_index - 3] = left
    placement_list[placement_index - 2] = top
    placement_list[placement_index - 1] = right
    placement_list[placement_index] = bottom

    return placement_index - 4
end

---gets a placement
---@param id integer placement_id
---@return number left
---@return number top
---@return number right
---@return number bottom
function draw_data.get_placement(id)
    return placement_list[id + 1], placement_list[id + 2], placement_list[id + 3], placement_list[id + 4]
end

---duplicates a placement
---@param id integer placement_id
---@return integer placement_id
function draw_data.dup_placement(id)
    return draw_data.make_placement(draw_data.get_placement(id))
end

---makes a coordinate point
---@param x number
---@param y number
---@return integer point_id
function draw_data.make_point(x, y)
    placement_index = placement_index + 3

    placement_list[placement_index - 2] = "point"
    placement_list[placement_index - 1] = x
    placement_list[placement_index] = y

    return placement_index - 2
end

---gets a coordinate point
---@param id integer
---@return number x
---@return number y
function draw_data.get_point(id)
    return placement_list[id + 1], placement_list[id + 2]
end

---adds a point cluster
---@param ... number
---@return integer point_cluster_id
function draw_data.make_point_cluster(...)
    placement_index = placement_index + 1
    local cluster_id = placement_index
    placement_list[placement_index] = "point_cluster"

    placement_index = placement_index + 1
    local size = select("#", ...)
    placement_list[placement_index] = size

    for i = 1, size do
        placement_index = placement_index + 1
        placement_list[placement_index] = select(i, ...)
    end

    return cluster_id
end

---gets a point cluster
---@param id integer
---@return number ...
function draw_data.get_point_cluster(id)
    return unpack(placement_list, id + 2, id + 1 + placement_list[id + 1])
end

---adds a push translation
---@param dx number
---@param dy number
---@return integer translation_id
function draw_data.make_push_translation(dx, dy)
    placement_index = placement_index + 3

    placement_list[placement_index - 2] = "push_translation"
    placement_list[placement_index - 1] = dx
    placement_list[placement_index] = dy

    return placement_index - 2
end

---edits a translation
---@param id integer
---@param new_x number
---@param new_y number
function draw_data.edit_translation(id, new_x, new_y)
    placement_list[id + 1] = new_x
    placement_list[id + 2] = new_y
end

draw_data.get_translation = draw_data.get_point

---adds a pop translation
---@return integer pop_translation_id
function draw_data.make_pop_translation()
    placement_index = placement_index + 1
    placement_list[placement_index] = "pop_translation"

    return placement_index
end

local tstack = require("ui.shared_data").volatile.translate_stack

---Edits all placements so they are offset by the applied translations. This function should only be run once per frame.
---This saves us some work later.
function draw_data.bake_translations()
    local prev_x, prev_y, length
    local tindex = 2
    local i = 1
    while i <= placement_index do
        if placement_list[i] == "placement" then
            if tindex > 2 then -- only apply transform if we need to
                placement_list[i + 1] = placement_list[i + 1] + tstack[tindex - 1] -- left
                placement_list[i + 2] = placement_list[i + 2] + tstack[tindex] -- top
                placement_list[i + 3] = placement_list[i + 3] + tstack[tindex - 1] -- right
                placement_list[i + 4] = placement_list[i + 4] + tstack[tindex] -- bottom
            end
            i = i + 5
        elseif placement_list[i] == "point" then
            if tindex > 2 then -- only apply transform if we need to
                placement_list[i + 1] = placement_list[i + 1] + tstack[tindex - 1] -- x
                placement_list[i + 2] = placement_list[i + 2] + tstack[tindex] -- y
            end
            i = i + 3
        elseif placement_list[i] == "point_cluster" then
            if tindex > 2 then -- only apply transform if we need to
                i = i + 1

                length = placement_list[i] -- get the length
                i = i + 1

                for j = 1, length do
                    placement_list[i] = placement_list[i] + tstack[tindex - j % 2] -- minus 1 for the x coordinate so this works
                    i = i + 1
                end
            else
                i = i + 2 + placement_list[i + 1]
            end
        elseif placement_list[i] == "push_translation" then
            prev_x, prev_y = tstack[tindex - 1], tstack[tindex]
            tindex = tindex + 2

            tstack[tindex - 1] = prev_x + placement_list[i + 1]
            tstack[tindex] = prev_y + placement_list[i + 2]

            i = i + 3
        elseif placement_list[i] == "pop_translation" then
            tindex = tindex - 2
            i = i + 1
        else
            error("invalid placement operation")
        end
    end
end

--#endregion

---Adds an operation.
---@param id integer
---@param ... any
function draw_data.add_draw_operation(id, ...)
    if draw_data_is_blocked then
        return
    end

    local slot_index

    if take_reservation_id and band(id, 0x1000) == 0 then
        -- take a reservation

        if res_list[take_reservation_id] == res_list[take_reservation_id - 1] then
            error("reservation is full")
        end

        res_list[take_reservation_id] = res_list[take_reservation_id] + 1
        slot_index = res_list[take_reservation_id]

        take_reservation_id = nil
    else
        draw_index = draw_index + 1
        slot_index = draw_index
    end

    draw_list[slot_index] = draw_list[slot_index] or {}
    local slot = draw_list[slot_index]

    if as_overlay and band(id, 0xF00) == 0x100 then
        id = bor(id, 0x200) -- normal and overlay differ by only one bit
        as_overlay = false
    end

    slot[ID_POS] = id
    for i = 1, math.max(select("#", ...), #slot) do
        slot[i + 1] = select(i, ...)
    end
end

---Blocks the addition of any further draw operations.
---Operations are enabled again after draw_data is reset is called.
function draw_data.block_draw_operations()
    draw_data_is_blocked = true
end

function draw_data.unblock_draw_operations()
    draw_data_is_blocked = false
end

---The next added draw operation will be converted into an overlay element if appropriate.
---Incompatible operations are ignored but do not de-assert this temporary state.
---Calling this multiple times does nothing.
function draw_data.next_as_overlay()
    as_overlay = true
end

--#region draw reservations

---Reserves the next n draw operations. Will cause an error/warning if not all reservations are taken later.
---@param n integer number of reservations
---@return integer res_id use this reference id to later fill in reservation slots
---@nodiscard
function draw_data.reserve_draw_slots(n)
    if draw_data_is_blocked then
        return 0
    end

    if n < 1 then
        error("can't reserve less than 1 slot")
    end

    -- reservation start and stop points
    local start, stop = draw_index, draw_index + n

    res_index = res_index + 2
    res_list[res_index - 1] = stop
    res_list[res_index] = start

    -- fill in the gap that the reservation leaves
    -- these slots are set up to be detected when drawing if they're not taken
    for i = 1, n do
        draw_list[draw_index + i] = draw_list[draw_index + i] or {}
        local slot = draw_list[draw_index + i]
        slot[ID_POS] = draw_operation.unused_reservation
        slot[3] = res_index
        slot[4] = i
        slot[5] = n
    end

    -- set the list_index to the end of the reservation
    draw_index = stop

    return res_index
end

---The next added draw operation will fill in a slot in a reservation.
---Calling this multiple times in a row will only make the next draw operation take the last given res_id.
---Incompatible operations are ignored but do not de-assert this temporary state.
---@param res_id integer the reservation id to fill
function draw_data.next_takes_reservation(res_id)
    if draw_data_is_blocked then
        return
    end

    if not (res_id > 0 and res_id <= res_index) then
        error("bad reservation id")
    end

    take_reservation_id = res_id
end

---Closes a reservation by plugging up all remaining slots with nops
---@param res_id integer the reservation id to fill
function draw_data.close_reservation(res_id)
    if not (res_id > 0 and res_id <= res_index) then
        error("bad reservation id")
    end

    local i, stop = res_list[res_id], res_list[res_id - 1]
    while i ~= stop do
        i = i + 1
        draw_list[i][ID_POS] = draw_operation.nop
    end
    res_list[res_id] = stop
end

--#endregion

---Returns an iterator that returns the placement location and draw operation parameters in a table.
---@return fun():table
function draw_data.iterate()
    return coroutine.wrap(function()
        -- we do it like this because the draw list might self modify
        local i = 1
        while i <= draw_index do
            coroutine.yield(draw_list[i])
            i = i + 1
        end
    end)
end

function draw_data.reset()
    placement_index = 0
    draw_index = 0
    res_index = 0
    take_reservation_id = nil
end

return draw_data
