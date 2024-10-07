local cursor = require("ui.cursor")
local theme = require("ui.theme")
local dragbox = require("ui.sensor.dragbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local mouse = require("ui.mouse")
local extmath = require("ui.extmath")
local sensor = require("ui.sensor")

local actuator_radius = element.slider_height / 2
local slot_height = element.slider_height / 2

---returns the closest position from 0 to positions - 1
---@param value number
---@param min number
---@param max number
---@param positions integer
---@return integer
local function get_closest_position(value, min, max, positions)
    local real_step = extmath.inverse_lerp(min, max, value) * (positions - 1)
    return math.ceil(real_step - 0.5)
end

---Slider element. This element will reshape the cursor.
---@param state table state
---@param min number min representable number in state.value
---@param max number max representable number in state.value
---@param positions integer number of valid slider positions
---@param show_positions boolean? show position lines; recommended if the slider is coarse.
return function(state, min, max, positions, show_positions)
    local divisions = positions - 1

    -- first time initialization
    state.position = state.position or 0
    state.value = state.value or min

    cursor.push() -- (1)

    local full_width = math.max(element.slider_min_width, cursor.width)
    cursor.place(full_width, element.slider_height)
    cursor.change_anchor(0, 0.5)

    -- absolute min and max slider coordinate positions
    local min_x, max_x = cursor.x + actuator_radius, cursor.x + full_width - actuator_radius
    local clamped_mouse_x = extmath.clamp(mouse.x, min_x, max_x)
    local step_size = (max_x - min_x) / divisions

    cursor.push() -- (2)

    local dragging = dragbox(state)
    local hovering = sensor.hovering

    -- background slot
    cursor.height = slot_height
    primitive.slot(theme.button_background)
    primitive.slot_outline(theme.button_outline)
    -- save background slot position for by show_positions
    cursor.push()

    -- get fill width and update position
    local fill_width
    if dragging or state.clicked or state.stopped_dragging then
        -- draw using mouse position
        fill_width = clamped_mouse_x - cursor.x

        -- set position and value
        state.position = get_closest_position(clamped_mouse_x, min_x, max_x, positions)
        state.value = extmath.map(state.position, 0, divisions, min, max)
    else
        -- draw using saved position
        fill_width = actuator_radius + state.position * step_size
    end

    -- background slot filled portion
    cursor.width = fill_width
    primitive.slot(theme.button_background_highlight)
    primitive.slot_outline(theme.accent_color)

    -- position lines
    if show_positions then
        cursor.peek()
        cursor.change_anchor(0.5)
        cursor.width = full_width - actuator_radius * 2
        cursor.height = cursor.height - 2 -- prevents lines from spilling over
        -- cursor.y = cursor.y + 12
        cursor.change_anchor(0)
        for x, i in cursor.xlinspace(positions) do
            cursor.x = math.floor(x)
            primitive.vline(i - 1 > state.position and theme.button_outline or theme.accent_color)
        end
        cursor.pop()
    else
        cursor.drop()
    end

    -- draw actuator
    cursor.x = fill_width + cursor.x
    cursor.anchor_x = 0.5
    cursor.width = element.slider_height
    cursor.height = element.slider_height
    primitive.circle(theme.toggle_actuator)
    primitive.circle_outline(
        (hovering or dragging) and theme.toggle_actuator_outline_highlight or theme.toggle_actuator_outline
    )

    cursor.pop() -- (2)
    cursor.do_auto_reshape() -- (1)
end
