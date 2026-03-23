--[[
    memoize v2.0
    Memoized functions in Lua
    https://github.com/kikito/memoize.lua

    MIT LICENSE

    Copyright (c) 2018 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- Inspired by http://stackoverflow.com/questions/129877/how-do-i-write-a-generic-memoize-function

-- Modified with the addition of a master sweep function

-- Lua 5.3 compatibility
local unpack = unpack or table.unpack

-- private stuff

local function is_callable(f)
    local tf = type(f)
    if tf == "function" then
        return true
    end
    if tf == "table" then
        local mt = getmetatable(f)
        return type(mt) == "table" and is_callable(mt.__call)
    end
    return false
end

local function cache_get(cache, params)
    local node = cache
    for i = 1, #params do
        node = node.children and node.children[params[i]]
        if not node then
            return nil
        end
    end
    if node.results then
        node.usage = (node.usage or 0) + 1
    end
    return node.results
end

local function cache_put(cache, params, results)
    local node = cache
    local param
    for i = 1, #params do
        param = params[i]
        node.children = node.children or {}
        node.children[param] = node.children[param] or {}
        node = node.children[param]
    end
    node.results = results
    node.usage = 1
end

-- Recursively sweep the cache tree, pruning nodes with usage 0.
-- Resets nodes with usage > 0 back to 0.
-- Removes empty subtrees on the way back up.
local function cache_sweep(node)
    if not node.children then
        return
    end

    for key, child in pairs(node.children) do
        cache_sweep(child)

        -- prune leaf: has results but usage is zero
        if child.results and child.usage == 0 then
            child.results = nil
            child.usage = nil
        end

        -- reset survivors
        if child.results then
            child.usage = 0
        end

        -- remove the child node entirely if it is now empty
        if not child.results and not child.children then
            node.children[key] = nil
        end
    end

    -- clean up the children table if it became empty
    if next(node.children) == nil then
        node.children = nil
    end
end

-- public functions

---@overload fun(f:function|table, cache:table?):function
local memoize = {}

local sweep_functions = {}

---@param f function|table something callable
---@param cache table? optionally provide a cache
---@return function
function memoize.memoize(f, cache)
    cache = cache or {}

    if not is_callable(f) then
        error(
            string.format("Only functions and callable tables are memoizable. Received %s (a %s)", tostring(f), type(f))
        )
    end

    local function memoized(...)
        local params = { ... }

        local results = cache_get(cache, params)
        if not results then
            results = { f(...) }
            cache_put(cache, params, results)
        end

        return unpack(results)
    end

    table.insert(sweep_functions, function()
        cache_sweep(cache)
    end)

    return memoized
end

---Sweeps all caches
function memoize.master_sweep()
    for i = 1, #sweep_functions do
        sweep_functions[i]()
    end
end

setmetatable(memoize --[[@as table]], {
    __call = function(_, ...)
        return memoize.memoize(...)
    end,
})

return memoize
