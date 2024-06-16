if os.getenv("COVERAGE") then
    require("luacov")
end
local ui = require("ui")
local state = require("ui.state")
local rectangle = require("ui.element.rectangle")
local label = require("ui.element.label")
local icon = require("ui.element.icon")
local area = require("ui.area")
local theme = require("ui.theme")
local scroll = require("ui.area.scroll")
local collapse = require("ui.area.collapse")
local id_table = require("ui.id_table")()
local signal = require("tests.signal")

-- build the test_list from a directory, files may implement certain functions to run tests
-- the list is flat despite the directory being hierarchial in order to allow for quick iteration
-- this is done by inserting a title for a directory -1 when it is going up again
local test_list = {}
local test_only_list = {} -- only contains real tests and not test list headings etc

local function build_test_tree(path)
    local directory_contents = love.filesystem.getDirectoryItems(path)
    for i = 1, #directory_contents do
        local file = directory_contents[i]
        local full_path = path .. "/" .. file
        local info = love.filesystem.getInfo(full_path)
        if info.type == "directory" then
            test_list[#test_list + 1] = file -- enter
            build_test_tree(full_path)
            test_list[#test_list + 1] = -1 -- exit
        else
            local require_path = full_path:gsub("/", "%."):gsub("%.lua", "")
            local contents = require(require_path)
            local test = { file:gsub("%.lua", ""), contents }
            test_list[#test_list + 1] = test
            test_only_list[#test_only_list + 1] = test
        end
    end
end

-- just unit tests for now
build_test_tree("tests/unit")

local current_test
local current_test_name

local red = { 1, 0, 0, 1 }
local green = { 0, 1, 0, 1 }

local automatic_execution = os.getenv("AUTOTEST") and true or false

---draw a test item
---@param item table
local function test_item(item)
    local name, content = unpack(item)
    -- select first test by default
    if current_test == nil then
        current_test = content
        current_test_name = name
    end
    if content == current_test then
        -- this test is selected
        theme.rectangle_color = theme.active_color
        rectangle()
        theme.rectangle_color = nil
        -- force collapse open if test is active and in collapse and if execution is automatic
        if automatic_execution then
            local data = area.get_extra_data()
            if data.state and data.state.height_signal then
                -- we are in one of our customized collapse areas!
                if data.state.height_factor ~= 1 then
                    data.state.height_signal:keyframe(0.1, 1)
                end
            end
        end
    else
        -- this test is not selected
        rectangle()
    end
    -- select this test if it was clicked
    if state.clicked then
        current_test = content
        current_test_name = name
    end
    -- test name
    label(name)
    -- indicate failure or success with an icon
    if content.failure or content.success then
        state.x = state.x + state.width -- left side of the rectangle
        -- store width and height since auto resizing overwrites it
        local old_width, old_height = state.width, state.height
        state.allow_automatic_resizing = true
        state.anchor.x = 1
        -- draw the icon
        if content.failure then
            theme.label_color = red
            icon("x-lg")
        elseif content.success then
            theme.label_color = green
            icon("check")
        end
        -- reset state to continue normally
        theme.label_color = nil
        state.anchor.x = 0
        state.allow_automatic_resizing = false
        state.width, state.height = old_width, old_height
        state.x = state.x - state.width
    end
    state.y = state.y + state.height + 10
end

---draw a new collapsible test list with title
---@param title string
local function start_test_list(title)
    -- next test list has this
    rectangle()
    -- initialize collapse state and store some of our own data (target and signal, used for animation)
    local coll_state = id_table[title]
    coll_state.height_factor = coll_state.height_factor or 0
    coll_state.height_target = coll_state.height_target or 0
    coll_state.height_signal = coll_state.height_signal or signal.new_queue()
    if state.clicked then
        -- open / close collapse when title rectangle is clicked
        coll_state.height_target = 1 - coll_state.height_target
        coll_state.height_signal:keyframe(0.1, coll_state.height_target)
    end
    coll_state.height_factor = coll_state.height_signal()
    -- draw test list title
    label(title)

    -- draw icon on the right and store width/height as auto resizing overwrites it
    state.x = state.x + state.width
    state.anchor.x = 1
    state.allow_automatic_resizing = true
    local last_width = state.width
    local last_height = state.height
    -- draw open/close arrow depending on collapse state
    if coll_state.height_target == 1 then
        icon("chevron-down")
    else
        icon("chevron-left")
    end
    -- reset state to continue normally
    state.width = last_width
    state.height = last_height
    state.allow_automatic_resizing = false
    state.anchor.x = 0
    state.x = state.x - state.width

    -- start the collapse for all further test items
    state.y = state.y + state.height + 10
    collapse.start(coll_state)
end

---end a test list, makes sure to respect collapse area size instead of content size
local function end_test_list()
    local bounds = area.get_bounds()
    bounds.bottom = bounds.bottom + 10
    collapse.done()
    state.y = bounds.bottom
end

---create the test selection, returns its width
---@return number
local function test_selection()
    local max_x = 0
    for i = 1, #test_list do
        local item = test_list[i]
        local item_type = type(item)

        -- all items in the list (test items or test list titles) are the same size
        state.allow_automatic_resizing = false
        state.width = 250
        state.height = 50

        if item_type == "string" then
            -- start test list
            start_test_list(item)
            state.x = state.x + 20
            max_x = math.max(state.x + state.width, max_x)
        elseif item_type == "number" then
            -- end test list
            state.x = state.x - 20
            end_test_list()
        elseif item_type == "table" then
            -- draw test item
            test_item(item)
        end
    end
    return max_x
end

local automatic_exit = os.getenv("AUTOCLOSE") and true or false
local current_index = 1 -- always starting at the beginning

local function run_next_test()
    if automatic_execution then
        current_index = current_index + 1
        if current_index > #test_only_list then
            current_index = #test_only_list
            if automatic_exit then
                love.event.push("quit")
            end
        end
        current_test_name = test_only_list[current_index][1]
        current_test = test_only_list[current_index][2]
    end
end

return function()
    -- signals are not included by default, update here
    signal.update(love.timer.getDelta())
    -- add a bit of padding before first rects
    state.x = 10
    state.y = 10
    -- draw scrollable test selection
    scroll.start(id_table.test_selection_scroll, "vertical", ui.get_height())
    local width = test_selection()
    scroll.done()
    -- go to the top of the window and to the right of the test selection which is where tests expect to start
    state.x = width + 10
    state.y = 10
    -- draw test layout if available
    if current_test.layout then
        current_test.layout()
    end
    -- execute test sequence if it exists and hasn't been executed already
    if current_test.sequence then
        if coroutine.status(current_test.sequence) == "suspended" then
            local success, err = coroutine.resume(current_test.sequence)
            if not success then
                -- finished (potentially partial) execution with error
                current_test.failure = err
                print(string.format("Failed %s: %s", current_test_name, err))
                current_test.success = false
                if current_test.teardown then
                    current_test.teardown()
                end
                run_next_test()
            elseif coroutine.status(current_test.sequence) == "dead" then
                -- finished whole execution (coroutine dead) without error
                print(current_test_name .. " succeeded")
                current_test.success = true
                if current_test.teardown then
                    current_test.teardown()
                end
                run_next_test()
            end
        end
    end
    -- draw error message at the bottom of test window if it failed
    if current_test.failure then
        state.y = ui.get_height()
        state.x = width + 10
        state.anchor.y = 1
        state.text_wraplimit = ui.get_width() - width - 10
        state.allow_automatic_resizing = true
        label("Test Failed: \n" .. current_test.failure)
    end
end
