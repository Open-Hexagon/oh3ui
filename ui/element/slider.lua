local cursor = require("ui.cursor")
local projected_placement = cursor.projected_placement
local theme = require("ui.theme")
local draw_by_cursor = require("ui.draw_queue").by_cursor
local element = require("ui.element")
local extmath = require("ui.extmath")
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local selection_outline = require("ui.decorator.element.selection_outline")

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
---@param kb_step integer? how many positions to move when using keyboard navigation
---@param kb_fast_step integer? how many positions to move after holding a key for longer than the hold time
---@param kb_hold_seconds number? how long a key needs to be held before faster movement is activated in seconds
---@return number value the "value" field of the state table
---@return integer position the "position" field of the state table
return function(state, min, max, positions, show_positions, kb_step, kb_fast_step, kb_hold_seconds)
    kb_step = kb_step or 1
    kb_fast_step = kb_fast_step or 5
    kb_hold_seconds = kb_hold_seconds or 1

    local divisions = positions - 1

    -- first time initialization
    if not state.initialized then
        state._slider_kb_hold_seconds = 0
        state.position = 0
        state.value = min
        state.initialized = true
    end

    cursor.push() -- (1)

    local full_width = math.max(element.slider_min_width, cursor.width)
    cursor.place(full_width, element.slider_height)
    cursor.change_anchor(0, 0.5)

    -- absolute min and max slider coordinate positions
    local min_x, max_x = projected_placement.left + actuator_radius, projected_placement.right - actuator_radius
    local clamped_mouse_x = extmath.clamp(mnav.x, min_x, max_x)
    local step_size = (max_x - min_x) / divisions

    cursor.push() -- (2)

    mnav.make_sensor(nil, smode.block, smode.draggable)

    if knav.get_holding() then
        state._slider_kb_hold_seconds = state._slider_kb_hold_seconds + love.timer.getDelta()
    else
        state._slider_kb_hold_seconds = 0
    end

    local kb_action = knav.get_action()
    if kb_action then
        if kb_action == kba.left then
            state.position = state.position - (state._slider_kb_hold_seconds > kb_hold_seconds and kb_fast_step or kb_step)
        elseif kb_action == kba.right then
            state.position = state.position + (state._slider_kb_hold_seconds > kb_hold_seconds and kb_fast_step or kb_step)
        end
        state.position = extmath.clamp(state.position, 0, divisions)
        state.value = extmath.map(state.position, 0, divisions, min, max)
    end

    -- background slot
    cursor.height = slot_height
    draw_by_cursor.slot(theme.widget_background)
    draw_by_cursor.slot_outline(theme.widget_outline)
    -- save background slot position for by show_positions
    cursor.push()

    -- get fill width and update position
    local fill_width
    local dragging, clicked = mnav.get_dragging() == mb.left, mnav.get_clicked() == mb.left
    if dragging then
        -- draw using mouse position
        fill_width = clamped_mouse_x - projected_placement.x

        -- set position and value
        state.position = get_closest_position(clamped_mouse_x, min_x, max_x, positions)
        state.value = extmath.map(state.position, 0, divisions, min, max)
    elseif clicked then
        -- set position and value
        state.position = get_closest_position(clamped_mouse_x, min_x, max_x, positions)
        state.value = extmath.map(state.position, 0, divisions, min, max)

        -- draw using saved position
        fill_width = actuator_radius + state.position * step_size
    else
        -- draw using saved position
        fill_width = actuator_radius + state.position * step_size
    end

    -- background slot filled portion
    cursor.width = fill_width
    draw_by_cursor.slot(theme.widget_background_highlight)
    draw_by_cursor.slot_outline(theme.accent_color)

    -- position lines
    if show_positions then
        cursor.peek()
        cursor.change_anchor(0.5)
        cursor.width = full_width - actuator_radius * 2
        cursor.height = cursor.height - 2 -- prevents lines from spilling over
        for x, i in cursor.h_linspace(positions) do
            cursor.x = x
            draw_by_cursor.vline(i - 1 > state.position and theme.widget_outline or theme.accent_color)
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
    draw_by_cursor.circle(theme.widget_actuator)
    draw_by_cursor.circle_outline(
        (mnav.is_hovering() or dragging) and theme.widget_actuator_outline_highlight or theme.widget_actuator_outline
    )

    cursor.pop() -- (2)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)
    return state.value, state.position
end
