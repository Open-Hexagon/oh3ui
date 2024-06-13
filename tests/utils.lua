local label = require("ui.element.label")
local state = require("ui.state")
local draw_queue = require("ui.draw_queue")
local utils = {}

utils.in_test = false
utils.mouse_x = 0
utils.mouse_y = 0

local old_get_pos = love.mouse.getPosition

function love.mouse.getPosition()
    if utils.in_test then
        return utils.mouse_x, utils.mouse_y
    else
        return old_get_pos()
    end
end

function utils.click()
    love.event.push("mousepressed", utils.mouse_x, utils.mouse_y, 1, false, 1)
    love.event.push("mousereleased", utils.mouse_x, utils.mouse_y, 1, false, 1)
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

local log = {}
log.__index = log
utils.log = log

function log.new()
    return setmetatable({}, log)
end

function log:add(...)
    local str = ""
    for i = 1, select("#", ...) do
        if i > 1 then
            str = str .. " " .. select(i, ...)
        else
            str = str .. select(i, ...)
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
