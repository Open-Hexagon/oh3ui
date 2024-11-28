-- luacov: disable
-- can't possibly cover line when luacov hasn't been included yet, so don't mark as miss
-- local test_menu = require("tests.menu")
local example_menu = require("ui.menu.example")

-- luacov: enable
local layers = require("ui.layers")
local ui = require("ui")

ui.scale = os.getenv("SCALE") or 1

function love.run()
    -- Target duration of each tick in seconds
    -- ? 240 tps seems a bit excessive for a user interface.
    -- local target_delta = 1 / 240
    local target_delta = 1 / 60
    local last_time = 0

    -- * testing menu
    layers.push(example_menu)

    -- keep this always on when using the ui
    love.keyboard.setKeyRepeat(true)

    return function()
        -- Process events
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                return 0
            end
            print(name, a, b, c, d, e, f)
            ui.push_event(name, a, b, c, d, e, f)
        end

        -- ui.scale = (math.sin(love.timer.getTime() * 10) + 1) * 0.2 + 0.8
        -- ui.scale = math.floor(ui.scale * 10) / 10

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
