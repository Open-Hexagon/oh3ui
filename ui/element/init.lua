---Elements will use the cursor to position themselves though they may not obey
---the cursor's bounding box and might end up larger or smaller than the cursor.

--[[
    -- Typical element structure
    function element()
        -- initialize the element

        push -- (1) push original cursor shape

            place -- determine location of element
            change_anchor -- anchor/position can be changed here but do_auto_reshape will revert it

            -- draw bottom full-size sub elements: sub-elements that are the same size as this element

            push -- (2) push the element location

                -- draw other sub elements

            pop -- (2) revert back to original element location

            -- draw top full-size sub elements: sub-elements that are the same size as this element

        do_auto_reshape -- (1) this will revert everything except for width and height if auto_reshape is true

        -- should immediately return
    end
]]

local element = {}

element.button_internal_padding = 8

element.toggle_width = 40
element.toggle_height = 20

element.slider_min_width = 100
element.slider_height = 20

element.numeric_input_min_width = 100
element.numeric_input_height = 20
element.numeric_input_lr_button_width = 16
element.numeric_input_text_size = 16

return element