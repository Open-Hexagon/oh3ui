-- luacov: disable
-- can't possibly cover line when luacov hasn't been included yet, so don't mark as miss
local test_menu = require("tests.menu")
-- luacov: enable
local layers = require("ui.layers")
local ui = require("ui")

function love.run()
    local target_delta = 1 / 240
    local last_time = 0
    layers.push(test_menu)
    return function()
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                return 0
            end
            ui.process_event(name, a, b, c, d, e, f)
        end
        love.graphics.setCanvas()
        --ui.scale = (math.sin(love.timer.getTime() * 10) + 1) * 0.2 + 0.8
        --ui.scale = math.floor(ui.scale * 10) / 10
        if love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(0, 0, 0, 1)
            ui.start()
            layers.run()
            ui.done()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(math.floor(love.timer.getFPS()) .. " fps")
            love.graphics.present()
        end
        love.timer.step()
        love.timer.sleep(target_delta - (love.timer.getTime() - last_time))
        last_time = last_time + target_delta
    end
end
