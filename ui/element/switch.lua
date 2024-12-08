local cursor = require("ui.cursor")
local theme = require("ui.theme")
local clickbox = require("ui.sensor.clickbox")
local primitive = require("ui.primitive")
local element = require("ui.element")
local mask = require("ui.mask")
local effect = require("ui.effect")
local reserve = require("ui.reserve")
local kba = require("ui.control.keyboard_action")
local mb = require("ui.control.mouse_button")
local selection_outline = require("ui.element.selection_outline")

local selection_highlight_speed = 25

---N-position switch
---@param state table state table
---@param ... string position names
---@return integer position the "position" field of the state table
return function(state, ...)
    local positions = select("#", ...)
    if not state.initialized then
        if positions < 2 then
            error("At least 2 positions need to be provided for switch")
        end
        for i = 1, positions do
            state[i] = {}
        end
        state.position = 1
        state.initialized = true
    end

    cursor.push() -- (1)

    local full_width = math.max(element.switch_height, cursor.width)
    cursor.place(full_width, element.slider_height)

    cursor.change_anchor(0.5)

    cursor.push() -- (2)

    local sel_bg_res = reserve.allocate(positions)
    local sel_hl_res = reserve.allocate(1)

    -- selection buttons
    local hovering = state.kb_selected
    local section_width = cursor.h_split(positions)
    for i = 1, positions do
        cursor.pop()
        local cb_state = state[i]
        clickbox(cb_state)
        if cb_state.clicked == mb.left then
            state._switch_selection_highlight_speed = math.abs(state.position - i) * selection_highlight_speed
            state.position = i
        end

        hovering = hovering or cb_state.hovering

        local button_color
        if cb_state.holding == mb.left or i == state.position then
            button_color = theme.widget_background_highlight
        elseif cb_state.hovering then
            button_color = theme.widget_background_brighter
        else
            button_color = theme.widget_background
        end

        reserve.take(sel_bg_res)
        primitive.rectangle(button_color)

        cursor.inset(element.switch_internal_padding)
        mask.push()
        primitive.label(select(i, ...), element.switch_text_size, "center", false)
        mask.pop()
    end

    -- keyboard navigation
    if not state.kb_is_repeat then
        if state.kb_action == kba.left then
            if state.position == 1 then
                state.position = positions
                state._switch_selection_highlight_speed = (positions - 1) * selection_highlight_speed
            else
                state.position = state.position - 1
                state._switch_selection_highlight_speed = selection_highlight_speed
            end
        elseif state.kb_action == kba.activate or state.kb_action == kba.right then
            if state.position == positions then
                state.position = 1
                state._switch_selection_highlight_speed = (positions - 1) * selection_highlight_speed
            else
                state.position = state.position + 1
                state._switch_selection_highlight_speed = selection_highlight_speed
            end
        end
    end

    cursor.peek()
    cursor.change_anchor(0)
    cursor.width = section_width
    local base_x = cursor.x
    state._switch_selection_highlight_position = effect.follow(
        state._switch_selection_highlight_position,
        state.position - 1,
        state._switch_selection_highlight_speed
    )
    cursor.x = base_x + state._switch_selection_highlight_position * section_width
    reserve.take(sel_hl_res)
    primitive.rectangle(theme.accent_color)

    cursor.pop() -- (2)
    primitive.rectangle_outline(hovering and theme.accent_color or theme.widget_outline)
    if state.kb_selected then
        selection_outline()
    end
    cursor.do_auto_reshape() -- (1)

    return state.position
end
