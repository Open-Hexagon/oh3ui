-- Parameters in the input table are set by the user.
local input = {
    anchor = {},
}

---reset manual input to default values
function input.reset()
    -- position
    input.x = 0
    input.y = 0
    input.width = 0
    input.height = 0
    -- x=0..1  0: left, 1: right
    -- y=0..1  0: top, 1: bottom
    input.anchor.x = 0
    input.anchor.y = 0

    -- text
    input.font = "assets/OpenSquare.ttf"
    input.font_size = 32
    input.text_wraplimit = math.huge
    input.text_align = "left"
    -- allow increasing element size automatically if too small
    input.allow_automatic_resizing = true
end

-- first input setup
input.reset()

return input
