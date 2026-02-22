-- luacov: disable
-- disable coverage while parsing arguments

local argparse = require("argparse")
local ui = require("ohui")
local ui_settings = ui.settings
local unittest = require("tests.unittest")

ui.theme.set_default("font_path", "assets/open-pentagon.ttf")
ui.theme.set_default("icon_font_path", "assets/open-pentagon.ttf")

local parser = argparse("ohce", "open hexagon community edition")

parser:flag("-e --print-events", "enable printing of events")
parser:option("-s --ui-scale", "starting ui scale", 1, tonumber, 1)
parser:option("-g --grid", "enable grid and set its size", nil, tonumber, "?"):action(function(args, _, list)
    args.grid = list[1] or 50
end)
parser
    :option("-u --unittest", "start unittest mode; optionally provide a filter", nil, nil, "?")
    :action(function(args, _, list)
        args.unittest = list[1] or ".*"
    end)
parser:flag("-v --verbose", "verbose output in unittest mode")
parser:flag("-c --coverage", "enable coverage in unittest mode")
parser:flag("-S --strict", "warnings become errors")
parser:option("-T --tickrate", "number of ticks per second (default is 60)", 60, tonumber, 1)
parser:flag("-k --overlay-masks", "overlay mask elements")
parser:flag("-m --overlay-mouse-sensors", "overlay mouse sensor elements")
parser:flag("-w --overlay-view-request", "overlay mouse view requests")

local arg_values = parser:parse(love.arg.parseGameArguments(arg))

local enable_event_printing = arg_values.print_events

local unittest_mode = not not arg_values.unittest
unittest.pattern = arg_values.unittest
unittest.verbose = arg_values.verbose

ui_settings.scale = arg_values.ui_scale
ui_settings.strict = unittest_mode or arg_values.strict
ui_settings.overlay_grid = arg_values.grid
ui_settings.overlay_masks = arg_values.overlay_masks
ui_settings.overlay_mouse_sensors = arg_values.overlay_mouse_sensors
ui_settings.overlay_view_request = arg_values.overlay_view_request

if arg_values.unittest and arg_values.coverage then
    require("luacov")
end

-- luacov: enable

local example_menu = require("menu.example")
-- local scroll_example = require("menu.scroll_example")

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
    if ui.settings.is_desktop then
        love.keyboard.setTextInput(true)
    end

    ui.layer.push({ main = example_menu })

    return function()
        -- Process events
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                return a or 0
            end
            if enable_event_printing then
                -- these joystick events are blacklisted because they're very noisy
                if name == "joystickaxis" then
                elseif name == "gamepadaxis" then
                else
                    print(name, a, b, c, d, e, f)
                end
            end
            ui.push_event(name, a, b, c, d, e, f)
        end

        if love.graphics.isActive() then
            -- reset everything
            love.graphics.setCanvas()
            love.graphics.origin()
            love.graphics.clear(0.1, 0.1, 0.1, 1)

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
