local scissor_stack = require("ui.draw_queue.scissor_stack")
local extmath = require("ui.extmath")
local sensor = require("ui.control.sensor")
local warning = require("ui.warning")
local draw_data = require("ui.draw_queue.draw_data")
local op_ids = require("ui.draw_queue.draw_operation")
local settings = require("ui.settings")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local bit = require("bit")
local band = bit.band

--[[
    * Aside: How ui scaling and transformations are done

    Old method

    apply transforms e.g. scale x2
    build the queue while passing any coordinate through transformPoint e.g x2 to all coordinate values
    undo all transforms
    draw elements using absolute coordinates (they all got scaled by x2 anyways)

    Upsides:
    - calling graphics transformations directly while building the queue works (even with weird stuff like rotate or skew).

    Downsides:
    - line widths are not scaled properly, they would have to be multiplied too.
    - May be confusing e.g. forgetting to pass coordinates through transformPoint.

    New method (currently implemented)

    apply transforms (this could go after "build queue" but we want [inverse]TransformPoint to work)
    build the queue
    draw elements with transforms
    undo transforms

    Upsides:
    - No need to remember to transform everything manually.
    - Transforms are completely accurate.

    Downsides:
    - calling graphics transformations has no effect while building the queue.
]]

---Execute all queued commands.
---This will also reset everything related to the queue
return function()
    local id, x1, y1, x2, y2, x3, y3, mode, rx, ry, line_width, r, g, b, a
    local width, height, half_width, radius, rotation, segments, text_object, sensor_id
    local tx1, ty1, tx2, ty2
    for item in draw_data.iterate() do
        id = item[1]
        if id > op_ids.nop then
            if id == op_ids.rectangle then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                mode, rx, ry, line_width, r, g, b, a = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(mode, x1, y1, x2 - x1, y2 - y1, rx, ry)
            elseif id == op_ids.rectangle_outline then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                line_width, rx, ry, r, g, b, a = unpack(item, 3)
                half_width = line_width * 0.5
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(
                    "line",
                    x1 + half_width,
                    y1 + half_width,
                    x2 - x1 - line_width,
                    y2 - y1 - line_width,
                    rx,
                    ry
                )
            elseif id == op_ids.rectangle_inline then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                line_width, rx, ry, r, g, b, a = unpack(item, 3)
                half_width = line_width * 0.5
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.rectangle(
                    "line",
                    x1 - half_width,
                    y1 - half_width,
                    x2 - x1 + line_width,
                    y2 - y1 + line_width,
                    rx,
                    ry
                )
            elseif id == op_ids.circle then
                x1, y1 = draw_data.get_point(item[2])
                mode, radius, r, g, b, a, line_width, rotation, segments = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                if rotation == 0 then
                    love.graphics.circle(mode, x1, y1, radius, segments)
                else
                    love.graphics.push()
                    love.graphics.translate(x1, y1)
                    love.graphics.rotate(rotation)
                    love.graphics.circle(mode, 0, 0, radius, segments)
                    love.graphics.pop()
                end
            elseif id == op_ids.circle_outline then
                x1, y1 = draw_data.get_point(item[2])
                radius, line_width, r, g, b, a, rotation, segments = unpack(item, 3)
                if segments then
                    -- use accurate inset
                    radius = extmath.inradius_offset(radius, segments, -0.5 * line_width)
                else
                    -- use approximation
                    radius = radius - 0.5 * line_width
                end
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                if rotation == 0 then
                    love.graphics.circle("line", x1, y1, radius, segments)
                else
                    love.graphics.push()
                    love.graphics.translate(x1, y1)
                    love.graphics.rotate(rotation)
                    love.graphics.circle("line", 0, 0, radius, segments)
                    love.graphics.pop()
                end
            elseif id == op_ids.polygon then
                mode, line_width, r, g, b, a = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.polygon(mode, draw_data.get_point_cluster(item[2]))
            elseif id == op_ids.line then
                line_width, r, g, b, a = unpack(item, 3)
                love.graphics.setLineWidth(line_width)
                love.graphics.setColor(r, g, b, a)
                love.graphics.line(draw_data.get_point_cluster(item[2]))
            elseif id == op_ids.text then
                x1, y1 = draw_data.get_point(item[2])
                text_object, r, g, b, a = unpack(item, 3)
                love.graphics.setColor(r, g, b, a)
                -- draw text objects without scaling for full resolution
                -- find out where the text should go after we undo the scaling
                tx1, ty1 = love.graphics.transformPoint(x1, y1)
                love.graphics.push()
                love.graphics.origin()
                love.graphics.draw(text_object, tx1, ty1)
                love.graphics.pop()

            -- * special
            elseif id == op_ids.push_scissor then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                -- scissor is not affected by graphics transforms
                tx1, ty1 = love.graphics.transformPoint(x1, y1)
                tx2, ty2 = love.graphics.transformPoint(x2, y2)
                scissor_stack.push(tx1, ty1, tx2, ty2)

                -- overlay masks
                -- luacov: disable
                if settings.overlay_masks then
                    -- we can reuse the placement
                    draw_data.add_draw_operation(
                        op_ids.rectangle_inline,
                        item[2], -- we can reuse the placement
                        2,
                        0,
                        0,
                        unpack(theme.get_xterm_color(157))
                    )
                end
                -- luacov: enable
            elseif id == op_ids.pop_scissor then
                scissor_stack.pop()
            elseif id == op_ids.mouse_sensor then
                x1, y1, x2, y2 = draw_data.get_placement(item[2])
                sensor_id, mode = unpack(item, 3)
                x3, y3, width, height = love.graphics.getScissor()

                -- sensor and mouse is not affected by graphics transforms
                tx1, ty1 = love.graphics.transformPoint(x1, y1)
                tx2, ty2 = love.graphics.transformPoint(x2, y2)

                if x3 then
                    tx1, ty1, tx2, ty2 =
                        extmath.aligned_rectangle_intersection(tx1, ty1, tx2, ty2, x3, y3, x3 + width, y3 + height)
                    -- only push if there was an intersection
                    if tx1 then
                        sensor.push(sensor_id, mode, tx1, ty1, tx2, ty2)
                    end
                else
                    -- push if there is no active scissor
                    sensor.push(sensor_id, mode, tx1, ty1, tx2, ty2)
                end

                -- overlay mouse sensors
                -- luacov: disable
                if tx1 and settings.overlay_mouse_sensors then
                    tx1, ty1 = love.graphics.inverseTransformPoint(tx1, ty1)
                    tx2, ty2 = love.graphics.inverseTransformPoint(tx2, ty2)
                    -- we cannot reuse the placement
                    draw_queue.by_value.rectangle_outline(tx1, ty1, tx2, ty2, theme.get_xterm_color(213), 2, 0, 0)
                end
                -- luacov: enable
            elseif id == op_ids.set_shader then
                love.graphics.setShader(item[2])

            -- * overlay
            elseif band(id, 0xF00) == 0x300 then
                draw_data.add_draw_operation(id - 0x200, unpack(item, 2))

            -- * other
            elseif id == op_ids.unused_reservation then
                warning(
                    string.format(
                        "unused reservation slot with res_id %d, slot number %d of %d",
                        item[2],
                        item[3],
                        item[4]
                    )
                )
            else
                -- luacov: disable
                -- should be unreachable
                error(string.format("unknown draw queue op id %d", id))
                -- luacov: enable
            end
        end
    end
end
