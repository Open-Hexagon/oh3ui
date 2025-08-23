-- luacov: disable
-- can't possibly cover line when luacov hasn't been included yet, so don't mark as miss

local argparse = require("argparse")
local ui_settings = require("ui.settings")
local unittest = require("tests.unittest")

-- local test_menu = require("tests.menu")
local example_menu = require("ui.menu.example")
local scroll_example_menu = require("ui.menu.scroll_example")
local area_behavior = require("ui.menu.area_behavior")
local translate_behavior = require("ui.menu.translate_behavior")

-- luacov: enable
local layers = require("ui.layers")
local ui = require("ui")

local enable_event_printing
local unittest_mode

local function load(args)
    local parser = argparse.new_parser("ohce", "open hexagon community edition")
    parser:add_argument("-e", "--print-events", "enable printing of events", 0, false, "store_true", false)
    parser:add_argument("-s", "--ui-scale", "starting ui scale", 1, true, nil, 1)
    parser:add_argument("-g", "--grid", "enable grid and set its size", "?", true, "store_const", nil, 50)
    parser:add_argument("-u", "--unittest", "start unittest mode", 0, false, "store_true", false)
    parser:add_argument("-v", "--verbose", "verbose output in unittest mode", 0, false, "store_true", false)

    local arg_values = parser:parse_args(args)

    ui_settings.scale = arg_values.ui_scale
    ui_settings.debug_grid = arg_values.grid
    enable_event_printing = arg_values.print_events
    unittest_mode = arg_values.unittest
    unittest.verbose = arg_values.verbose
end

function love.run()
    ---this function exists
    ---@diagnostic disable-next-line: undefined-field
    load(love.arg.parseGameArguments(arg))

    -- Target duration of each tick in seconds
    local target_delta = 1 / 60
    local last_time = 0

    -- keep this always on when using the ui
    love.keyboard.setKeyRepeat(true)

    if unittest_mode then
        return unittest.main
    end

    -- layers.push(example_menu)
    -- layers.push(area_behavior)
    layers.push(translate_behavior)

    return function()
        -- Process events
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                return a or 0
            end
            if enable_event_printing then
                print(name, a, b, c, d, e, f)
            end
            ui.push_event(name, a, b, c, d, e, f)
        end

        if love.graphics.isActive() then
            -- reset everything
            love.graphics.setCanvas()
            love.graphics.origin()
            love.graphics.clear(0, 0, 0, 1)

            ui.start()
            layers.run()
            ui.finish()

            -- draw the fps
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(math.floor(love.timer.getFPS()) .. " fps")
            love.graphics.present()
        end

        -- Ensure tick rate is kept steady
        love.timer.step()
        love.timer.sleep(target_delta - (love.timer.getTime() - last_time))
        last_time = last_time + target_delta
    end
end
