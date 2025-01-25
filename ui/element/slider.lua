local cursor = require("ui.cursor")
local placement = cursor.placement
local theme = require("ui.theme")
local dragbox = require("ui.sensor.dragbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local mouse = require("ui.control.mouse")
local extmath = require("ui.extmath")
local kba = require("ui.control.keyboard_action")
local kb_nav = require("ui.control.keyboard_navigation")
local selection_outline = require("ui.decorator.selection_outline")

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
---@param state table state table
---@param min number min representable number in state.value
---@param max number max representable number in state.value
---@param positions integer number of valid slider positions
---@param show_positions boolean? show position lines; recommended if the slider is coarse.
---@return number value the "value" field of the state table
---@return integer position the "position" field of the state table
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
    local min_x, max_x = placement.left + actuator_radius, placement.right - actuator_radius
    local clamped_mouse_x = extmath.clamp(mouse.x, min_x, max_x)
    local step_size = (max_x - min_x) / divisions

    cursor.push() -- (2)

    local dragging = dragbox(state)
    local hovering = state.hovering

    local kb_action = kb_nav.get_action()
    if kb_action then
        if kb_action == kba.left then
            state.position = state.position - 1
        elseif kb_action == kba.right then
            state.position = state.position + 1
        end
        state.position = extmath.clamp(state.position, 0, divisions)
        state.value = extmath.map(state.position, 0, divisions, min, max)
    end

    -- background slot
    cursor.height = slot_height
    primitive.slot(theme.widget_background)
    primitive.slot_outline(theme.widget_outline)
    -- save background slot position for by show_positions
    cursor.push()

    -- get fill width and update position
    local fill_width
    if dragging or state.holding or state.stopped_dragging then
        -- draw using mouse position
        fill_width = clamped_mouse_x - placement.x

        -- set position and value
        state.position = get_closest_position(clamped_mouse_x, min_x, max_x, positions)
        state.value = extmath.map(state.position, 0, divisions, min, max)
    else
        -- draw using saved position
        fill_width = actuator_radius + state.position * step_size
    end

    -- background slot filled portion
    cursor.width = fill_width
    primitive.slot(theme.widget_background_highlight)
    primitive.slot_outline(theme.accent_color)

    -- position lines
    if show_positions then
        cursor.peek()
        cursor.change_anchor(0.5)
        cursor.width = full_width - actuator_radius * 2
        cursor.height = cursor.height - 2 -- prevents lines from spilling over
        for x, i in cursor.h_linspace(positions) do
            cursor.x = x
            primitive.vline(i - 1 > state.position and theme.widget_outline or theme.accent_color)
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
    primitive.circle(theme.widget_actuator)
    primitive.circle_outline(
        (hovering or dragging) and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline
    )

    cursor.pop() -- (2)

    if kb_nav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)
    return state.value, state.position
end
