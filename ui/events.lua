-- Handles a list of love events.
-- At the beginning of each frame, all love events shall be added to the list.
-- This list can then be read by all ui elements.

local events = {}

-- an ordered list of events for the current frame
local sequence = {}
local length = 0

---Push a love event to the event sequence.
---All love events should be pushed at the very beginning of a frame.
---@param ... unknown
function events.add(...)
    length = length + 1
    local event = sequence[length]
    if event then
        -- overwrite old event values if the table aready exists
        for i = 1, math.max(select("#", ...), #event) do
            event[i] = select(i, ...)
        end
    else
        -- make a new table if one doesn't already exist
        sequence[length] = { ... }
    end
end

---clear the event queue
function events.clear()
    -- refill table without removing prior content
    -- reduces memory allocation
    length = 0
end

---iterate over the event tables and filter for specific event names if required
---(processed events are not removed so they can be processed in different places!)
---@param filter?
---|string # a string pattern that is matched against a love event name
---|fun(event_name:string):any # a function that returns something truthy if an event is matched
---@return fun():table
---@nodiscard
function events.iterate(filter)
    if type(filter) == "string" then
        return coroutine.wrap(function()
            for i = 1, length do
                local event = sequence[i]
                if string.match(event[1], filter) then
                    coroutine.yield(event)
                end
            end
        end)
    elseif type(filter) == "function" then
        return coroutine.wrap(function()
            for i = 1, length do
                local event = sequence[i]
                if filter(event[1]) then
                    coroutine.yield(event)
                end
            end
        end)
    else
        return coroutine.wrap(function()
            for i = 1, length do
                coroutine.yield(sequence[i])
            end
        end)
    end
end

return events
