local utils = require("tests.utils")
local id_table = require("ui.id_table")()
local state = require("ui.state")
local test = {}

local log = utils.log.new()

function test.layout()
    state.allow_automatic_resizing = true
    log:draw()
    state.allow_automatic_resizing = false
end

local function get_keys(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys+1] = k
    end
    return keys
end

test.sequence = coroutine.create(function()
    log:add("id table keys:", unpack(get_keys(id_table)))
    for i = 1, 5 do
        local key = "test" .. i
        log:add("getting " .. key)
        assert(type(id_table[key]) == "table", "id table key is not a table")
        local keys = get_keys(id_table)
        local is_in = false
        for j = 1, #keys do
            if keys[j] == key then
                is_in = true
                break
            end
        end
        assert(is_in, "key is not in key list")
        log:add("id table keys:", unpack(keys))
    end
end)

return test
