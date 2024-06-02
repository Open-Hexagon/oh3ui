local test_menu = require("ui.menu.test")
local ui = require("ui")

function love.run()
    return function()
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                return 0
            end
            ui.process_event(name, a, b, c, d, e, f)
        end
        love.graphics.setCanvas()
        --ui.scale = (math.sin(love.timer.getTime()) + 1) * 0.2 + 0.8
        if love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(0, 0, 0, 1)
            ui.start()
            test_menu()
            ui.done()
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(math.floor(love.timer.getFPS()) .. " fps")
            love.graphics.present()
        end
        love.timer.step()
    end
end
