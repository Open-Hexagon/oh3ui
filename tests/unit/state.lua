local state = require("ui.state")
local utils = require("tests.utils")
local area = require("ui.area")

local log = utils.log.new()
local test = {}

function test.layout()
    state.allow_automatic_resizing = true
    log:draw()
    state.allow_automatic_resizing = false
end

-- most of this is already tested extensively, so there are just some basic tests for reset and area interactability here
test.sequence = coroutine.create(function()
    log:add("checking reset")
    state.reset()
    assert(state.x == 0, "x is wrong")
    assert(state.y == 0, "y is wrong")
    assert(state.width == 0, "width is wrong")
    assert(state.height == 0, "height is wrong")
    assert(state.anchor.x == 0, "anchor x is wrong")
    assert(state.anchor.y == 0, "anchor y is wrong")
    assert(state.font == "assets/OpenSquare.ttf", "font is wrong")
    assert(state.font_size == 32, "font size is wrong")
    assert(state.text_wraplimit == math.huge, "wraplimit is wrong")
    assert(state.text_align == "left", "text align is wrong")
    assert(state.allow_automatic_resizing, "auto resizing should be allowed")
    assert(state.current_area_index == 0, "area stack should be reset")
    assert(state.left == 0, "left bound is wrong")
    assert(state.right == 0, "right bound is wrong")
    assert(state.top == 0, "top bound is wrong")
    assert(state.bottom == 0, "bottom bound is wrong")
    assert(not state.hovering, "should not be hovering")
    assert(not state.clicked, "should not be clicked")

    log:add("checking area interactability")
    area.start()
    assert(state.is_position_interactable(10, 10), "position should be interactable")
    local data = area.get_extra_data()
    data.state = {}
    data.state.cutout = {}
    data.state.cutout.left = 0
    data.state.cutout.right = 0
    data.state.cutout.top = 0
    data.state.cutout.bottom = 0
    assert(not state.is_position_interactable(10, 10), "position should not be interactable")
    area.done()
end)

return test
