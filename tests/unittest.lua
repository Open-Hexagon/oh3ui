---Unit testing fixture

local buffer = require("string.buffer")

local unittest = {
    verbose = false,
    pattern = nil,
}

-- stats
local total_tests = 0
local tests_passed = 0
local tests_failed = 0
local tests_skipped = 0
local tests_errored = 0

---Build and return a list of tests from a directory, files may implement certain functions to run tests. The list is flat.
---@param test_cases table
---@param start_dir string starting directory to begin discovery
---@param name_pattern string a file's name has to match this pattern to be included (%.lua is automatically appended)
local function discover_tests(test_cases, start_dir, name_pattern)
    local directory_contents = love.filesystem.getDirectoryItems(start_dir)

    for i = 1, #directory_contents do
        local filename = directory_contents[i]
        local full_path = start_dir .. "/" .. filename
        local info = love.filesystem.getInfo(full_path)

        if info.type == "directory" then
            -- descend into folder
            discover_tests(test_cases, full_path, name_pattern)
        elseif info.type == "file" then
            local found, _, name = string.find(filename, "^(" .. name_pattern .. ")%.lua$")
            if found then
                local require_path = start_dir:gsub("/", "%.") .. "." .. name
                local test_case = require(require_path)
                if type(test_case) == "table" then
                    if not test_case.unittest_ignore then
                        test_case._file_path = full_path
                        table.insert(test_cases, test_case)
                    end
                elseif unittest.verbose then
                    io.stderr:write(
                        string.format(
                            "\x1b[34m[note] ignoring test file `%s` that didn't return a table\x1b[0m\n",
                            full_path
                        )
                    )
                end
            end
        end
    end
end

local YK_FAILED_ASSERT = debug.upvalueid(discover_tests, 1)
local YK_SKIPPED = debug.upvalueid(discover_tests, 2)

local function add_pass(msg)
    tests_passed = tests_passed + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;32m[PASSED]\x1b[0m ", msg, "\n")
    else
        io.stderr:write(".")
    end
end

local function add_empty(msg)
    -- empty tests have technically passed
    tests_passed = tests_passed + 1
    if unittest.verbose then
        io.stderr:write("\x1b[2m[EMPTY]\x1b[0m ", msg, "\n")
    else
        io.stderr:write("_")
    end
end

local function add_fail(msg)
    tests_failed = tests_failed + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;31m[FAILED]\x1b[0m ", msg, "\n")
    else
        io.stderr:write("F")
    end
end

local function add_skip(msg)
    tests_skipped = tests_skipped + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;33m[SKIPPED]\x1b[0m ", msg, "\n")
    else
        io.stderr:write("S")
    end
end

local function add_error(msg)
    tests_errored = tests_errored + 1
    if unittest.verbose then
        io.stderr:write("\x1b[1;41m[ERROR]\x1b[0m ", msg, "\n")
    else
        io.stderr:write("E")
    end
end

local has_assertions = false

---Assert for unit testing. Lets us distinguish assertions from actual errors.
---@param v any
---@param msg string?
function unittest.assert(v, msg)
    has_assertions = true
    if not v then
        local loc_info = debug.getinfo(2, "Sl")
        coroutine.yield(YK_FAILED_ASSERT, msg, string.format("%s:%s:", loc_info.short_src, loc_info.currentline))
    end
end

---asserts that a function causes an error
---@param fn function
---@param msg string?
---@param ... any
function unittest.assert_error(fn, msg, ...)
    has_assertions = true
    if pcall(fn, ...) then
        local loc_info = debug.getinfo(2, "Sl")
        coroutine.yield(YK_FAILED_ASSERT, msg, string.format("%s:%s:", loc_info.short_src, loc_info.currentline))
    end
end

---Asserts that lists are equal. Gives detailed info about what doesn't match.
---Only checks lengths and integer keys 1 and above.
---@param t1 table
---@param t2 table
---@param msg string?
function unittest.assert_equal_lists(t1, t2, msg)
    has_assertions = true
    local l1 = #t1
    local l2 = #t2
    if l1 ~= l2 then
        local loc_info = debug.getinfo(2, "Sl")
        if msg then
            coroutine.yield(
                YK_FAILED_ASSERT,
                string.format("%s (table lengths are not equal #t1 == %d, #t2 == %d)", msg, l1, l2),
                string.format("%s:%s:", loc_info.short_src, loc_info.currentline)
            )
        else
            coroutine.yield(
                YK_FAILED_ASSERT,
                string.format("table lengths are not equal #t1 == %d, #t2 == %d", l1, l2),
                string.format("%s:%s:", loc_info.short_src, loc_info.currentline)
            )
        end
    end
    for i = 1, l1 do
        if t1[i] ~= t2[i] then
            local loc_info = debug.getinfo(2, "Sl")
            if msg then
                coroutine.yield(
                    YK_FAILED_ASSERT,
                    string.format("%s (table items at index %d are not equal)", msg, i),
                    string.format("%s:%s:", loc_info.short_src, loc_info.currentline)
                )
            else
                coroutine.yield(
                    YK_FAILED_ASSERT,
                    string.format("table items at index %d are not equal", i),
                    string.format("%s:%s:", loc_info.short_src, loc_info.currentline)
                )
            end
        end
    end
end

---Asserts that two objects are equal by using LuaJIT serialization.
---May throw an error when attempting to check unsupported object types, circular references or deeply nested tables.
---@param o1 any
---@param o2 any
---@param msg string?
function unittest.assert_equal_objects(o1, o2, msg)
    has_assertions = true
    if buffer.encode(o1) ~= buffer.encode(o2) then
        local loc_info = debug.getinfo(2, "Sl")
        coroutine.yield(YK_FAILED_ASSERT, msg, string.format("%s:%s:", loc_info.short_src, loc_info.currentline))
    end
end

---checks if two numbers are close
---@param a number
---@param b number
---@param msg string?
---@param epsilon number?
function unittest.assert_almost_equals(a, b, msg, epsilon)
    has_assertions = true
    epsilon = epsilon or 1e-6
    if not (a - epsilon <= b and b <= a + epsilon) then
        local loc_info = debug.getinfo(2, "Sl")
        coroutine.yield(YK_FAILED_ASSERT, msg, string.format("%s:%s:", loc_info.short_src, loc_info.currentline))
    end
end

---skips a test
---@param reason string?
function unittest.skip(reason)
    local loc_info = debug.getinfo(2, "Sl")
    coroutine.yield(YK_SKIPPED, reason, string.format("%s:%s:", loc_info.short_src, loc_info.currentline))
end

---skips a test if condition is true
---@param cond any
---@param reason string?
function unittest.skip_if(cond, reason)
    if cond then
        local loc_info = debug.getinfo(2, "Sl")
        coroutine.yield(YK_SKIPPED, reason, string.format("%s:%s:", loc_info.short_src, loc_info.currentline))
    end
end

---@param test_case table
---@return table
---@return integer
---@return thread? co_set_up_case the set_up_case function becomes a coroutine
local function extract_tests(test_case)
    local tests, num_tests = {}, 0
    local co_set_up_case
    for fn_name, fn in pairs(test_case) do
        if type(fn) == "function" then
            local fn_info = debug.getinfo(fn, "S")
            if string.find(fn_name, "^test[_0-9a-zA-Z]*") then
                num_tests = num_tests + 1
                tests[num_tests] =
                    { fn_name, coroutine.create(fn), string.format("%s:%s:", fn_info.short_src, fn_info.linedefined) }
            elseif fn_name == "set_up_case" then
                co_set_up_case = coroutine.create(fn)
            elseif fn_name == "set_up" then
                -- doesn't become a coroutine
            elseif fn_name == "tear_down" then
                -- doesn't become a coroutine
            elseif fn_name == "tear_down_case" then
                -- doesn't become a coroutine
            elseif unittest.verbose then
                io.stderr:write(
                    string.format(
                        "\x1b[33m[warning] %s:%s: extraneous function `%s` in test case\x1b[0m\n",
                        fn_info.short_src,
                        fn_info.linedefined,
                        fn_name
                    )
                )
            end
        end
    end
    return tests, num_tests, co_set_up_case
end

---Runs a test case
---@param test_case table
local function run_test_case(test_case)
    local test_success, test_msg, success, kind, msg, loc

    local tests, num_tests, co_set_up_case = extract_tests(test_case)
    if num_tests == 0 and unittest.verbose then
        io.stderr:write(string.format("\x1b[34m[note] %s has no tests\x1b[0m\n", test_case._file_path))
        return
    end
    total_tests = total_tests + num_tests

    ---@param fn function? a set up or tear down function
    ---@return boolean success true if the function succeeds or doesn't exist
    local function try_call(fn)
        if fn then
            success, msg = pcall(fn)
            return success
        end
        return true
    end

    -- set_up_case is run as a coroutine since if a skip is made in that function, we should skip the entire test case
    if co_set_up_case then
        ::again::
        success, kind, msg, loc = coroutine.resume(co_set_up_case)
        if success then
            if kind == YK_FAILED_ASSERT then
                -- ignore assertions
                goto again
            elseif kind == YK_SKIPPED then
                if unittest.verbose then
                    io.stderr:write(
                        string.format(
                            "\x1b[33m[skipped] %s %s (entire test case skipped; +%d skipped)\x1b[0m\n",
                            loc,
                            msg or "(no reason given)",
                            num_tests
                        )
                    )
                else
                    io.stderr:write("\x1b[33m", string.rep("s", num_tests), "\x1b[39m")
                end
                tests_skipped = tests_skipped + num_tests
                return
            end
        else
            if unittest.verbose then
                io.stderr:write(
                    string.format(
                        "\x1b[31m[error] %s (in set_up_case; all tests skipped; +%d errors)\x1b[0m\n",
                        kind,
                        num_tests
                    )
                )
            else
                io.stderr:write("\x1b[31m", string.rep("e", num_tests), "\x1b[39m")
            end
            tests_errored = tests_errored + num_tests
            return
        end
    end

    for i = 1, num_tests do
        local fn_name, fn, fn_def_loc = unpack(tests[i])

        -- test set_up
        if not try_call(test_case.set_up) then
            add_error(string.format("%s (in set_up of %s)", msg or "(no description)", fn_name))
            goto continue
        end

        has_assertions = false
        test_success, kind, test_msg, loc = coroutine.resume(fn)

        -- tear_down always gets called if set_up succeeds
        if not try_call(test_case.tear_down) then
            -- if this fails, report as an error
            add_error(string.format("%s (in tear_down of %s)", msg or "(no description)", fn_name))
            goto continue
        end

        -- record test data
        if test_success then
            if kind == YK_FAILED_ASSERT then
                add_fail(string.format("%s %s %s", loc, fn_name, test_msg or "(no message given)"))
            elseif kind == YK_SKIPPED then
                add_skip(string.format("%s %s %s", loc, fn_name, test_msg or "(no reason given)"))
            elseif not has_assertions then
                add_empty(string.format("%s %s", fn_def_loc, fn_name))
            else
                add_pass(string.format("%s %s OK", fn_def_loc, fn_name))
            end
        else
            add_error(kind or "(no description)")
        end

        ::continue::
    end

    if not try_call(test_case.tear_down_case) and unittest.verbose then
        io.stderr:write(
            string.format("\x1b[31m[error] %s (in tear_down_case; errors may cascade to later tests)\x1b[0m\n", msg)
        )
        return
    end
end

function unittest.main()
    love.event.pump()

    local test_cases = {}
    discover_tests(test_cases, "tests/unit", unittest.pattern)

    -- The order in which tests cases are run may change between executions
    local group_state, last_total, next_lf = false, total_tests, 80
    for i = 1, #test_cases do
        run_test_case(test_cases[i])

        -- highlight certain characters to hint at test groups
        if not unittest.verbose and total_tests > last_total then
            if group_state then
                io.stderr:write("\x1b[27m")
            else
                io.stderr:write("\x1b[7m")
            end
            last_total = total_tests
            group_state = not group_state

            if total_tests > next_lf then
                io.stderr:write("\n")
                next_lf = next_lf + 80
            end
        end
    end

    -- print footer
    if not unittest.verbose then
        io.stderr:write("\x1b[0m")
        io.stderr:write("\n")
    end
    io.stderr:write(string.rep("-", 10), "\n")
    io.stderr:write(
        string.format(
            "total: %d, passed: %d, failed: %d, skipped: %d, errors: %d\n",
            total_tests,
            tests_passed,
            tests_failed,
            tests_skipped,
            tests_errored
        )
    )

    -- causes love2d to exit immediately
    return 0
end

return unittest
