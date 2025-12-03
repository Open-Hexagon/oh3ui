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
local econf = {}

econf.toggle_width = 40
econf.toggle_height = 20

econf.slider_min_width = 100
econf.slider_height = 20

econf.switch_min_width = 100
econf.switch_height = 20
econf.switch_text_size = 16
econf.switch_internal_padding = 2

econf.numeric_input_min_width = 100
econf.numeric_input_height = 20
econf.numeric_input_lr_button_width = 16
econf.numeric_input_text_size = 16

econf.checkbox_size = 22

econf.selection_outline_outset = 4
econf.selection_outline_line_width = 2

econf.tooltip_text_padding = 4
econf.tooltip_element_spacing = 6

econf.scrollbar_thickness = 8
econf.scrollbar_thickness_inactive = econf.scrollbar_thickness * 0.5
econf.minimum_scrollbar_actuator_length = 8
econf.mouse_wheel_scroll_distance = 10 -- px/event
econf.view_request_padding = econf.scrollbar_thickness * 1.5
econf.view_request_speed = 10 -- this is the reciprocal of the time it takes for the animation
econf.view_request_scrollbar_cooldown_time = 1.5 -- starting from an auto-scroll, the scrollbars will remain visible for this amount of time

econf.collapse_speed = 1800 -- px/sec

return econf
