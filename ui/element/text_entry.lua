local typing = require("ui.control.typing")
local primitive = require("ui.primitive")
local cursor = require("ui.cursor")
local placement = cursor.placement
local mask = require("ui.mask")
local mouse = require("ui.control.mouse")

---Text entry element. This element requires a clickbox to be used on the given state table since this element itself does not itself check for mouse clicks. 
---The cursor will only determine the text location.
---@param state table
---@param size number? override font size in pixels
---@param align love.AlignMode? override alignment mode
---@param color number[]? override text color
---@param font_path string? override text.font
return function(state, size, align, color, font_path)
    cursor.push()

    mask.push()
    cursor.auto_reshape = true
    primitive.label(state.text, size, align, color, font_path)
    mask.pop()

    if state.clicked then
        typing.set_target(state)
    end

    cursor.do_auto_reshape()
end
