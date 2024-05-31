local area = require("ui.area")
local wheel_interaction = require("ui.interaction.scroll.wheel")
local grab_interaction = require("ui.interaction.scroll.grab")
local touch_interaction = require("ui.interaction.scroll.touch")
local scroll = {}

local has_scrolled_this_frame = false

---resets scroll state for the frame
function scroll.reset()
    has_scrolled_this_frame = false
    grab_interaction.reset()
end

function scroll.go_to(position, duration, interpolation)
    local scroll_state = area.get_extra_data().state
    scroll_state.start_position = scroll_state.position
    scroll_state.target_position = position
    scroll_state.interpolation = interpolation or "none"
    scroll_state.interpolation_start_time = love.timer.getTime()
    scroll_state.interpolation_duration = duration or 1
end

---update the current scroll area
function scroll.update()
    local data = area.get_extra_data()
    local scroll_state = data.state

    -- decrease scroll velocity over time (increased and used in touch scroll)
    scroll_state.velocity = scroll_state.velocity or 0
    if scroll_state.velocity < 0 then
        scroll_state.velocity = math.min(0, scroll_state.velocity + love.timer.getDelta() * 500)
    else
        scroll_state.velocity = math.max(0, scroll_state.velocity - love.timer.getDelta() * 500)
    end

    -- user can only interact with one scroll area at the same time
    if has_scrolled_this_frame then
        return
    end

    -- make sure that the default is always in the past
    scroll_state.last_interaction_time = scroll_state.last_interaction_time or -2

    scroll_state.target_position = scroll_state.target_position or 0
    scroll_state.interpolation_start_time = scroll_state.interpolation_start_time or 0
    scroll_state.interpolation_duration = scroll_state.interpolation_duration or 1

    -- actually process the different types of scroll interaction
    wheel_interaction(scroll_state)
    grab_interaction.update(scroll_state)
    touch_interaction(scroll_state)

    -- limit target position to area bounds
    if scroll_state.target_position > data.overflow then
        scroll_state.target_position = data.overflow
    elseif scroll_state.target_position < 0 then
        scroll_state.target_position = 0
    end

    -- this area was interacted with
    if scroll_state.target_position ~= scroll_state.position then
        has_scrolled_this_frame = true
        -- show scrollbar again until it fades out
        scroll_state.scrollbar_alpha = 1
        scroll_state.last_interaction_time = love.timer.getTime()
    else
        -- fade out scrollbar after a while (stays at 1 for 0.5s and gone completely after 1.5s)
        scroll_state.scrollbar_alpha = 1.5 + scroll_state.last_interaction_time - love.timer.getTime()
        if scroll_state.scrollbar_alpha > 1 then
            scroll_state.scrollbar_alpha = 1
        elseif scroll_state.scrollbar_alpha < 0 then
            scroll_state.scrollbar_alpha = 0
        end
    end

    -- move towards target position
    local factor = math.min((love.timer.getTime() - scroll_state.interpolation_start_time) / scroll_state.interpolation_duration, 1)
    if scroll_state.interpolation == "none" then
        scroll_state.position = scroll_state.target_position
    elseif scroll_state.interpolation == "linear" then
        scroll_state.position = scroll_state.start_position * (1 - factor)  + scroll_state.target_position * factor
    elseif scroll_state.interpolation == "out_sine" then
        factor = math.sin(factor * math.pi / 2)
        scroll_state.position = scroll_state.start_position * (1 - factor)  + scroll_state.target_position * factor
    end
end

return scroll
