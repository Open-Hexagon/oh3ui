---Uses the debug library to get or set function upvalues.
---Used to peek at local variables of modules.

local upvalue = {}

function upvalue.get_by_name(f, ...)
    local len = select("#", ...)
    local out = {}

    local name, value
    local i = 1

    while true do
        name, value = debug.getupvalue(f, i)
        if not name then
            break
        end

        for j = 1, len do
            if name == select(j, ...) then
                out[j] = value
            end
        end
        i = i + 1
    end

    return unpack(out)
end

function upvalue.set_by_name(f, name, value)
    local name2
    local i = 1
    while true do
        name2 = debug.getupvalue(f, i)
        if not name2 then
            break
        end
        if name == name2 then
            debug.setupvalue(f, i, value)
            return
        end
        i = i + 1
    end
    error(string.format("upvalue %s doesn't exist", name2), 2)
end

return upvalue
