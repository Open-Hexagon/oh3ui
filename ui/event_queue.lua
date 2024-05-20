local event_queue = {}
local queue = {}
local length = 0

---add an event to the queue for interactions to use
---@param ... unknown
function event_queue.add(...)
    length = length + 1
    local event = queue[length]
    if event then
        for i = 1, math.max(select("#", ...), #event) do
            event[i] = select(i, ...)
        end
    else
        queue[length] = { ... }
    end
end

---clear the event queue
function event_queue.clear()
    -- refill table without removing prior content
    -- reduces memory allocation
    length = 0
end

---iterate over the event tables and filter for specific event names if required
-- (processed events are not removed so they can be processed in different places!)
---@param filter string?
---@return fun():table
function event_queue.iterate(filter)
    if filter then
        return coroutine.wrap(function()
            for i = 1, length do
                local event = queue[i]
                if event[1]:match(filter) then
                    coroutine.yield(event)
                end
            end
        end)
    else
        return coroutine.wrap(function()
            for i = 1, length do
                coroutine.yield(queue[i])
            end
        end)
    end
end

return event_queue
