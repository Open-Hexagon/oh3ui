local unittest = require("tests.unittest")
local id_table = require("ui.id_table")()

local T = {}

local function get_keys(t)
    local keys = {}
    for k in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function T.test_id_table()
    for i = 1, 5 do
        local key = "test" .. i
        unittest.assert(type(id_table[key]) == "table", "id table key is not a table")
        local keys = get_keys(id_table)
        local is_in = false
        for j = 1, #keys do
            if keys[j] == key then
                is_in = true
                break
            end
        end
        unittest.assert(is_in, "key is not in key list")
    end
end

return T
