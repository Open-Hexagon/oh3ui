---Elements will use the cursor to position themselves though they may not obey
---the cursor's bounding box and might end up larger or smaller than the cursor.

--[[
    -- Typical element structure
    function element()
        -- initialize the element
        -- do state changes

        push() -- (1) push original cursor shape
        do

            place -- determine location of element
            change_anchor -- anchor/position can be changed here but do_auto_reshape will revert it

            -- draw bottom full-size sub elements: sub-elements that are the same size as this element

            push() -- (2) push the element location
            do

                -- draw other sub elements

            end
            pop() -- (2) revert back to original element location

            -- draw top full-size sub elements: sub-elements that are the same size as this element
            
        end
        -- ! The cursor must match the shape of the whole final element before running do_auto_reshape or else this isn't going to work.
        -- ! do_auto_reshape doesn't know how big your element actually is. It just assumes where you left the cursor is the full size of the element. 
        do_auto_reshape() -- (1) this will revert everything except for width and height if auto_reshape is true

        -- should immediately return
    end
]]

---Note: modifying values in this table will not live-update the appearance of elements since some elements will cache them
local ep = {}

ep.toggle_width = 40
ep.toggle_height = 20

ep.slider_min_width = 100
ep.slider_height = 20

ep.switch_min_width = 100
ep.switch_height = 20
ep.switch_text_size = 16
ep.switch_internal_padding = 2

ep.numeric_input_min_width = 100
ep.numeric_input_height = 20
ep.numeric_input_lr_button_width = 16
ep.numeric_input_text_size = 16

ep.checkbox_size = 22

ep.selection_outline_outset = 4
ep.selection_outline_line_width = 2

ep.tooltip_text_padding = 4
ep.tooltip_element_spacing = 6

ep.scrollbar_thickness = 8
ep.scrollbar_thickness_inactive = ep.scrollbar_thickness * 0.5
ep.minimum_scrollbar_actuator_length = 8
ep.mouse_wheel_scroll_distance = 10 -- px/event
ep.view_request_padding = ep.scrollbar_thickness * 1.5
ep.view_request_speed = 10 -- this is the reciprocal of the time it takes for the animation
ep.view_request_scrollbar_cooldown_time = 1.5 -- starting from an auto-scroll, the scrollbars will remain visible for this amount of time

ep.collapse_speed = 100--1800 -- px/sec

return ep
