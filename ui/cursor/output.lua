-- The cursor will put its output in this table when a commit is run.
-- Elements should typically only read from the output table.

local output = {
    left = 0,
    top = 0,
    right = 0,
    bottom = 0,
}

return output
