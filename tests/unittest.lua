---Unit testing fixture

local unittest = {
    verbose = false,
}

---Build and return a list of tests from a directory, files may implement certain functions to run tests
---The list is flat
---@param start_dir string starting directory to begin discovery
---@param name_pattern string a file's name has to match this pattern to be included (%.lua is automatically appended)
---@return table
local function discover_tests(start_dir, name_pattern)
    local test_cases = {}

    local directory_contents = love.filesystem.getDirectoryItems(start_dir)

    for i = 1, #directory_contents do
        local filename = directory_contents[i]
        local full_path = start_dir .. "/" .. filename
        local info = love.filesystem.getInfo(full_path)

        if info.type == "directory" then
            -- descend into folder
            discover_tests(full_path, name_pattern)
        elseif info.type == "file" then
            local found, _, name = string.find(filename, "^(" .. name_pattern .. ")%.lua$")
            if found then
                local require_path = start_dir:gsub("/", "%.") .. "." .. name
                local test_case = require(require_path)
                assert(type(test_case) == "table", string.format("test file `%s` didn't return a table", full_path))
                test_case._file_path = full_path
                table.insert(test_cases, test_case)
            end
        end
    end

    return test_cases
end

-- stats
local total_tests = 0
local tests_passed = 0
local tests_failed = 0
local tests_errored = 0

-- scratch variables
local current_test_name
local test_failed
local test_failed_msg

local function add_pass(msg)
    tests_passed = tests_passed + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;32m[PASSED]\x1b[0m ", msg, current_test_name, " OK\n")
    else
        io.stderr:write(".")
    end
end

local function add_fail(msg)
    tests_failed = tests_failed + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;31m[FAILED]\x1b[0m ", msg, current_test_name)
        if test_failed_msg then
            io.stderr:write(" message: `", test_failed_msg, "`")
        end

        io.stderr:write("\n")
    else
        io.stderr:write("F")
    end
end

local function add_error(msg)
    tests_errored = tests_errored + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;41m[ERROR]\x1b[0m ", msg or "no description", " (in ", current_test_name, ")\n")
    else
        io.stderr:write("E")
    end
end

local function skip_case(msg)
    if unittest.verbose then
        io.stderr:write("\x1b[1;33m[SKIP CASE]\x1b[0m ", msg or "no description", "\n")
    end
end

---Assert for unit testing. Lets us distinguish assertions from actual errors.
---@param v any
---@param msg string?
function unittest.assert(v, msg)
    if not v then
        test_failed = true
        test_failed_msg = msg
        error("", 2)
    end
end

---asserts that a function causes an error
---@param fn function
---@param msg string?
---@param ... any
function unittest.assert_error(fn, msg, ...)
    if pcall(fn, ...) then
        test_failed = true
        test_failed_msg = msg
        error("", 2)
    end
end

---Runs a test case
---@param test_case table
---@return boolean error returns true if this test case had an error
local function run_test_case(test_case)
    local tests, num_tests = {}, 0
    for fn_name, fn in pairs(test_case) do
        if string.find(fn_name, "^test[_0-9a-zA-Z]*") then
            num_tests = num_tests + 1
            tests[num_tests] = { fn_name, fn }
        end
    end

    if num_tests == 0 then
        skip_case(test_case._file_path .. " has no tests")
        return false
    end

    if test_case.set_up_case and not xpcall(test_case.set_up_case, skip_case) then
        return false
    end

    total_tests = total_tests + num_tests
    -- using goto to replicate continue, because otherwise this is a nightmare
    for i = 1, num_tests do
        local fn_name, fn = unpack(tests[i])

        -- test set_up
        current_test_name = "set_up of " .. fn_name
        if test_case.set_up and not xpcall(test_case.set_up, add_error) then
            -- if set_up errors, then report as error, not a failure
            goto continue
        end

        test_failed = false
        test_failed_msg = nil
        local success, msg = pcall(fn)

        -- tear_down always gets called if set_up succeeds
        current_test_name = "tear_down of " .. fn_name
        if test_case.tear_down and not xpcall(test_case.tear_down, add_error) then
            -- if tear_down errors, then report as error, not a failure
            goto continue
        end

        -- record test data
        current_test_name = fn_name
        if success then
            local fn_info = debug.getinfo(fn, "S")
            add_pass(string.format("%s:%s: ", fn_info.short_src, fn_info.linedefined))
        else
            if test_failed then
                add_fail(msg)
            else
                add_error(msg)
            end
        end

        ::continue::
    end

    if test_case.tear_down_case and not pcall(test_case.tear_down_case) then
        io.stderr:write("\x1b[31merror occurred in tear_down_case in ", test_case._file_path, "\x1b[0m\n")
        return true
    end

    return false
end

function unittest.main()
    local test_cases = discover_tests("tests", "test.*")

    local i, num_test_cases = 1, #test_cases
    while i <= num_test_cases do
        if run_test_case(test_cases[i]) then
            break
        end
        i = i + 1
    end

    -- print footer
    if not unittest.verbose then
        io.stderr:write("\n")
    end
    io.stderr:write(string.rep("-", 10), "\n")
    if i < num_test_cases + 1 then
        io.stderr:write("\x1b[33mwarning: testing ended prematurely\x1b[0m\n")
    end
    io.stderr:write(
        string.format(
            "total: %d, passed: %d, failed: %d, errors: %d\n",
            total_tests,
            tests_passed,
            tests_failed,
            tests_errored
        )
    )

    -- causes love2d to exit immediately
    return 0
end

return unittest
