-- luacov: disable
-- disable coverage while parsing arguments

local unittest = require("tests.unittest")
local argparse = require("argparse")
local ui_settings = require("ui.settings")

local parser = argparse.new_parser("ohce", "open hexagon community edition")
parser:add_argument("-e", "--print-events", "enable printing of events", 0, false, "store_true", false)
parser:add_argument("-s", "--ui-scale", "starting ui scale", 1, true, nil, 1)
parser:add_argument("-g", "--grid", "enable grid and set its size", "?", true, "store_const", nil, 50)
parser:add_argument("-u", "--unittest", "start unittest mode", 0, false, "store_true", false)
parser:add_argument("-v", "--verbose", "verbose output in unittest mode", 0, false, "store_true", false)
parser:add_argument("-c", "--coverage", "enable coverage in unittest mode", 0, false, "store_true", false)
parser:add_argument("-S", "--strict", "warnings become errors", 0, false, "store_true", false)
parser:add_argument("-T", "--tickrate", "number of ticks per second (default is 60)", 1, true, nil, 60)

local arg_values = parser:parse_args(love.arg.parseGameArguments(arg))

ui_settings.scale = arg_values.ui_scale
ui_settings.debug_grid = arg_values.grid
local enable_event_printing = arg_values.print_events
local unittest_mode = arg_values.unittest
ui_settings.strict = unittest_mode or arg_values.strict
unittest.verbose = arg_values.verbose

if arg_values.unittest and arg_values.coverage then
    require("luacov")
end

-- luacov: enable

local example_menu = require("ui.menu.example")
local ui = require("ui")

function love.run()
    if unittest_mode then
        return unittest.main
    end

    -- luacov: disable
    -- Coverage can only be active when unit tesing. Anything past this point is never reached.

    -- Target duration of each tick in seconds
    local target_delta = 1 / arg_values.tickrate
    local last_time = 0

    -- keep this always on when using the ui
    love.keyboard.setKeyRepeat(true)

    ui.init(example_menu)

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

            ui.run()

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

    -- luacov: enable
end
