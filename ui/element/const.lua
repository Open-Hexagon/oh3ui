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

local const = {}

const.toggle_width = 40
const.toggle_height = 20

const.checkbox_size = 20

const.slider_min_width = 100
const.slider_height = 20

const.switch_min_width = 100
const.switch_height = 20
const.switch_text_size = 16
const.switch_internal_padding = 2

const.numeric_input_min_width = 100
const.numeric_input_height = 20
const.numeric_input_lr_button_width = 16
const.numeric_input_text_size = 16

const.checkbox_size = 22

return const