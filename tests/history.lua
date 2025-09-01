-- Patches and records arguments of called functions

local monkeypatch = require("tests.monkeypatch")

local history = {}

local list = {}
local list_index = 0

---@param item any
function history.add(item)
    list_index = list_index + 1
    list[list_index] = item
end

---@param n integer shouldn't be positive
---@return any
function history.get(n)
    return list[list_index + n]
end

function history.get_length()
    return list_index
end

function history.clear()
    for i = 1, list_index do
        list[i] = nil
    end
    list_index = 0
end

---@param orig_fn function
---@param tag string
---@return function
function history.patch(orig_fn, tag)
    return monkeypatch.replace(orig_fn, function(...)
        history.add({ tag, ... })
    end)
end

history.get_original = monkeypatch.get_original

return history
