local label = require("ui.element.label")
local state = require("ui.state")
local draw_queue = require("ui.draw_queue")
local monkeypatch = require("tests.monkeypatch")
local utils = {}

utils.mouse_x = 0
utils.mouse_y = 0

function utils.start_mouse_control()
    love.mouse.getPosition = monkeypatch.replace(love.mouse.getPosition, function()
        return utils.mouse_x, utils.mouse_y
    end)
end

function utils.stop_mouse_control()
    love.mouse.getPosition = monkeypatch.get_original(love.mouse.getPosition)
end

local cursor_color = { 1, 0.5, 0.5, 0.5 }
local cursor_radius = 3

function utils.fake_mouse_cursor()
    draw_queue.rectangle(
        "line",
        utils.mouse_x - cursor_radius,
        utils.mouse_y - cursor_radius,
        utils.mouse_x + cursor_radius,
        utils.mouse_y + cursor_radius,
        cursor_color,
        cursor_radius,
        cursor_radius
    )
end

local touches = {}
local id_counter = 0

function utils.create_touch()
    id_counter = (id_counter + 1) % 256
    local touch = {
        id = id_counter,
        pressure = 1,
        x = 0,
        y = 0,
    }
    touches[#touches + 1] = touch
    return touch
end

function utils.delete_touch(t)
    for i = 1, #touches do
        if touches[i] == t then
            table.remove(touches, i)
            return
        end
    end
end

local function get_touch(id)
    for i = 1, #touches do
        if touches[i].id == id then
            return touches[i]
        end
    end
end

function utils.start_touch_control()
    touches = {}
    id_counter = 0
    love.touch.getTouches = monkeypatch.replace(love.touch.getTouches, function()
        local ids = {}
        for i = 1, #touches do
            ids[i] = touches[i].id
        end
        return ids
    end)
    love.touch.getPosition = monkeypatch.replace(love.touch.getPosition, function(id)
        local touch = get_touch(id)
        return touch.x, touch.y
    end)
    love.touch.getPressure = monkeypatch.replace(love.touch.getPressure, function(id)
        return get_touch(id).pressure
    end)
end

function utils.stop_touch_control()
    love.touch.getTouches = monkeypatch.get_original(love.touch.getTouches)
    love.touch.getPosition = monkeypatch.get_original(love.touch.getPosition)
    love.touch.getPressure = monkeypatch.get_original(love.touch.getPressure)
end

local touch_cursor_color = { 0.5, 1, 0.5, 0.5 }
local touch_cursor_radius = 6

function utils.fake_touch_cursors()
    for i = 1, #touches do
        draw_queue.rectangle(
            "line",
            touches[i].x - touch_cursor_radius,
            touches[i].y - touch_cursor_radius,
            touches[i].x + touch_cursor_radius,
            touches[i].y + touch_cursor_radius,
            touch_cursor_color,
            touch_cursor_radius,
            touch_cursor_radius
        )
    end
end

local graphic_functions = { "rectangle", "polygon", "draw" }

function utils.add_graphics_callback(fun)
    for i = 1, #graphic_functions do
        local name = graphic_functions[i]
        love.graphics[name] = monkeypatch.add(love.graphics[name], function(...)
            fun(name, ...)
        end)
    end
end

function utils.remove_graphics_callback()
    for i = 1, #graphic_functions do
        local name = graphic_functions[i]
        love.graphics[name] = monkeypatch.get_original(love.graphics[name])
    end
end

function utils.wait(seconds)
    local start_time = love.timer.getTime()
    while love.timer.getTime() - start_time < seconds do
        coroutine.yield()
    end
end

function utils.click()
    love.event.push("mousepressed", utils.mouse_x, utils.mouse_y, 1, false, 1)
    love.event.push("mousereleased", utils.mouse_x, utils.mouse_y, 1, false, 1)
end

function utils.drag(dx, dy, steps)
    love.event.push("mousepressed", utils.mouse_x, utils.mouse_y, 1, false, 1)
    coroutine.yield()
    for _ = 1, steps do
        utils.mouse_x = utils.mouse_x + dx / steps
        utils.mouse_y = utils.mouse_y + dy / steps
        coroutine.yield()
    end
    love.event.push("mousereleased", utils.mouse_x, utils.mouse_y, 1, false, 1)
end

function utils.wheel(change)
    love.event.push("wheelmoved", 0, change)
end

function utils.check_color_at(x, y, check_color)
    local color = {}
    love.graphics.captureScreenshot(function(img_data)
        color[1], color[2], color[3], color[4] = img_data:getPixel(love.graphics.transformPoint(x, y))
    end)
    coroutine.yield() -- wait a frame for screenshot to be taken
    for i = 1, 4 do
        if color[i] ~= check_color[i] then
            return false
        end
    end
    return true
end

local log = {}
log.__index = log
utils.log = log

function log.new()
    return setmetatable({}, log)
end

function log:add(...)
    local str = ""
    for i = 1, select("#", ...) do
        local value = tostring(select(i, ...))
        if i > 1 then
            str = str .. " " .. value
        else
            str = str .. value
        end
    end
    self[#self + 1] = str
end

function log:draw()
    for i = 1, #self do
        label(self[i])
        state.y = state.y + state.height
    end
end

return utils
