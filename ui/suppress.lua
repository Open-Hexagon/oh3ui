local draw_data = require("ui.draw_queue.draw_data")
local set_shader_op_id = require("ui.draw_queue.draw_operation").set_shader

local disabled_shader = love.graphics.newShader([[
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    color *= texturecolor;
    color.rgb *= 0.5;
    return color;
}
]])

local disable_level = 0
local keepout_level = 0

local suppress = {}

function suppress.push_keepout()
    keepout_level = keepout_level + 1
end

function suppress.pop_keepout()
    if keepout_level == 0 then
        error("keepout is already off")
    end
    keepout_level = keepout_level - 1
end

function suppress.push_disable()
    if disable_level == 0 then
        draw_data.add_draw_operation(set_shader_op_id, disabled_shader)
    end
    disable_level = disable_level + 1
end

function suppress.pop_disable()
    if disable_level == 1 then
        draw_data.add_draw_operation(set_shader_op_id)
    elseif disable_level == 0 then
        error("disable is already off")
    end
    disable_level = disable_level - 1
end

function suppress.is_suppressed()
    return disable_level > 0 or keepout_level > 0
end

return suppress
