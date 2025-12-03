local cursor = require("ui.cursor")
local theme = require("ui.theme")
local draw_by_cursor = require("ui.draw_queue").by_cursor
local econf = require("ui.element_conf")
local extmath = require("extmath")
local selection_outline = require("ui.decorator.element.selection_outline").set_placement
local mnav = require("ui.control.mouse_navigation")
local mb = mnav.buttons
local smode = mnav.sensor_mode
local knav = require("ui.control.keyboard_navigation")
local kba = knav.actions
local typing = require("ui.control.typing")

---Combination number slider and entry with increment buttons.
---This element will reshape the cursor.
---@param state table state table
---@param min number min representable number in state.value
---@param max number max representable number in state.value
---@param step number step size for the increment and decrement buttons
---@param decimals integer Number of decimals of precision. Default is 0, 2 means the smallest step is 0.01, -1 means the smallest step is 10.
---@param format string? format string for the number display
---@return number value the "value" field of the state table
return function(state, min, max, step, decimals, format)
    -- first time initialization
    if not state.initialized then
        state.value = 0
        state.initialized = true
    end

    -- make sensor ids
    local everything_sid = mnav.declare_sensor_id()
    local left_sid = mnav.declare_sensor_id()
    local center_sid = mnav.declare_sensor_id()
    local right_sid = mnav.declare_sensor_id()

    typing.make_text_entry(state, center_sid)
    local is_editing = typing.is_editing(state)

    cursor.push() -- (1)

    -- set base shape
    local full_width = math.max(econf.numeric_input_min_width, cursor.width)
    cursor.place(full_width, econf.numeric_input_height)

    local center_width = cursor.width - econf.numeric_input_lr_button_width * 2

    cursor.auto_reshape = false
    cursor.change_anchor(0.5)

    cursor.push() -- (2)

    -- center
    cursor.width = center_width

    mnav.make_sensor(center_sid, smode.block, smode.draggable)

    local hovering = false
    local dragging = nil
    local center_hovering = false

    if not is_editing then
        hovering = mnav.is_hovering(everything_sid) or knav.is_selected()
        dragging = mnav.get_dragging(center_sid)
        center_hovering = mnav.is_hovering(center_sid)

        -- stop the mouse from reaching the edges of the screen
        if mnav.get_started_dragging(center_sid) == mb.left then
            love.mouse.setRelativeMode(true)
        elseif mnav.get_stopped_dragging(center_sid) == mb.left then
            love.mouse.setRelativeMode(false)
        end

        -- change the mouse cursor to <-> when hovering the center
        if state._numeric_input_center_hover_prev ~= center_hovering then
            state._numeric_input_center_hover_prev = center_hovering
            if center_hovering then
                love.mouse.setCursor(love.mouse.getSystemCursor("sizewe"))
            else
                love.mouse.setCursor()
            end
        end
    end

    if typing.started_editing(state) then
        love.mouse.setCursor()
        love.mouse.setRelativeMode(false)
    end

    -- #region Draw Background

    if dragging == mb.left then
        -- highlighted background
        cursor.width = full_width
        draw_by_cursor.rectangle(theme.widget_background_highlight)

        -- increment/decrement value
        state.value = state.value + mnav.screen_dx * 10 ^ -decimals

        -- prevent the mouse from moving when dragging
        love.mouse.setPosition(love.graphics.transformPoint(mnav.press_x, mnav.press_y))
    else
        -- normal background
        cursor.width = full_width
        draw_by_cursor.rectangle(theme.widget_background)
        cursor.width = center_width

        -- brighter center
        if center_hovering then
            draw_by_cursor.rectangle(theme.widget_background_brighter)
        end
    end

    -- #endregion

    -- ## Arrows
    if hovering or dragging == mb.left then
        local kb_action, kb_holding

        -- #region Left Arrow
        cursor.peek()
        cursor.change_anchor(0)
        cursor.width = econf.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        if not dragging then
            kb_action = knav.get_action()
            kb_holding = knav.get_holding()
            mnav.make_sensor(left_sid, smode.block)
            if mnav.get_clicked(left_sid) == mb.left or kb_action == kba.left then
                state.value = state.value - step
            end
            if mnav.get_holding(left_sid) == mb.left or kb_holding == kba.left then
                draw_by_cursor.rectangle(theme.widget_background_highlight)
            elseif mnav.is_hovering(left_sid) then
                draw_by_cursor.rectangle(theme.widget_background_brighter)
            end
        end
        draw_by_cursor.icon("chevron-left", econf.numeric_input_text_size)
        -- #endregion

        -- #region right arrow
        cursor.peek()
        cursor.change_anchor(1, 0)
        cursor.width = econf.numeric_input_lr_button_width
        cursor.change_anchor(0.5)

        if not dragging then
            mnav.make_sensor(right_sid, smode.block)
            if mnav.get_clicked(right_sid) == mb.left or kb_action == kba.right then
                state.value = state.value + step
            end
            if mnav.get_holding(right_sid) == mb.left or kb_holding == kba.right then
                draw_by_cursor.rectangle(theme.widget_background_highlight)
            elseif mnav.is_hovering(right_sid) then
                draw_by_cursor.rectangle(theme.widget_background_brighter)
            end
        end
        draw_by_cursor.icon("chevron-right", econf.numeric_input_text_size)
        -- #endregion
    end

    cursor.pop() -- (2)

    if typing.stopped_editing(state) then
        local n = tonumber(state.text)
        if n then
            state.value = n
        end
        typing.truncate(state)
    end

    state.value = extmath.clamp(extmath.round(state.value, decimals), min or -math.huge, max or math.huge)

    if is_editing then
        typing.draw_text_entry(econf.numeric_input_text_size, "input")
    else
        draw_by_cursor.label(string.format(format or "%f", state.value), econf.numeric_input_text_size, "left", false)
    end
    draw_by_cursor.rectangle_outline(
        (hovering or dragging or is_editing) and theme.widget_outline_highlight or theme.widget_outline
    )
    mnav.make_sensor(everything_sid)

    if knav.is_selected() then
        selection_outline()
    end

    cursor.do_auto_reshape() -- (1)

    return state.value
end
