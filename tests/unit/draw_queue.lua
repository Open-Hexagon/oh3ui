local utils = require("tests.utils")
local text_cache = require("ui.text_cache")
local draw_queue = require("ui.draw_queue")
local id_table = require("ui.id_table")()
local state = require("ui.state")
local ui = require("ui")
local test = {}

local log = utils.log.new()

function test.layout()
    state.allow_automatic_resizing = true
    state.text_wraplimit = ui.get_width() - state.x
    log:draw()
    state.text_wraplimit = math.huge
    state.allow_automatic_resizing = false
end

function test.teardown()
	utils.remove_graphics_callback()
end

-- adds some entries to the draw queue and checks if the resulting data matches
test.sequence = coroutine.create(function()
	local test_color = { 0.1, 0.2, 0.3, 0.4 }
	local draw_calls = {}
	utils.add_graphics_callback(function(graphics_fun, ...)
		local color = {love.graphics.getColor()}
		for i = 1, 4 do
			-- need to round because floats are dumb
			if math.floor(color[i] * 10) / 10 ~= test_color[i] then
				-- color does not match, draw call is not part of test
				return
			end
		end
		-- color matches, draw call is part of test
		draw_calls[#draw_calls + 1] = { graphics_fun, ... }
		log:add("executing", graphics_fun, ...)
	end)
	log:add("queueing commands")
	local width = love.graphics.getWidth()
	local invtrans = love.graphics.inverseTransformPoint
	do
		local x1, y1 = invtrans(width - 100, 10)
		local x2, y2 = invtrans(width - 10, 50)
		draw_queue.rectangle("fill", x1, y1, x2, y2, test_color, 10, 20)
	end
	do
		local x1, y1 = invtrans(width - 10, 10)
		local x2, y2 = invtrans(width - 50, 50)
		local x3, y3 = invtrans(width - 25, 45)
		draw_queue.polygon("fill", { x1, y1, x2, y2, x3, y3 }, test_color)
	end
	do
		local x, y = invtrans(width - 200, 100)
		draw_queue.text("Hello", love.graphics.getFont(), x, y, test_color, 200, "center")
	end
	local check_text_object = text_cache.get(love.graphics.getFont(), "Hello", 200, "center")
	coroutine.yield()
	log:add("checking data in commands")
	do
		local graphics_fun, mode, x, y, rect_width, rect_height, rx, ry = unpack(draw_calls[1])
		assert(graphics_fun == "rectangle", "first entry is not a rectangle")
		assert(mode == "fill", "mode is not fill")
		assert(x == width - 100, "x position is wrong")
		assert(y == 10, "y position is wrong")
		assert(rect_width == 90, "width is wrong")
		assert(rect_height == 40, "height is wrong")
		assert(rx == 10, "x radius is wrong")
		assert(ry == 20, "y radius is wrong")
	end
	do
		local graphics_fun, mode, x1, y1, x2, y2, x3, y3 = unpack(draw_calls[2])
		assert(graphics_fun == "polygon", "second entry is not a polygon")
		assert(mode == "fill", "mode is not fill")
		assert(x1 == width - 10, "x1 position is wrong")
		assert(y1 == 10, "y1 position is wrong")
		assert(x2 == width - 50, "x2 position is wrong")
		assert(y2 == 50, "y2 position is wrong")
		assert(x3 == width - 25, "x3 position is wrong")
		assert(y3 == 45, "y3 position is wrong")
	end
	do
		local graphics_fun, text_object, x, y = unpack(draw_calls[3])
		assert(text_object == check_text_object, "text object does not match same one gotten from cache")
		assert(x == width - 200, "x position is wrong")
		assert(y == 100, "y position is wrong")
	end
	log:add("done")
end)

return test
