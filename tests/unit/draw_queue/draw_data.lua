local unittest = require("tests.unittest")
local draw_data = require("ui.draw_queue.draw_data")

local T = {}

function T.tear_down()
    draw_data.clear()
end

function T.test_()

end

return T
