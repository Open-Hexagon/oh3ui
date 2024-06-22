local scroll = require("ui.area.scroll")
local rectangle = require("ui.element.rectangle")
local layers = require("ui.layers")
local state = require("ui.state")
local area = require("ui.area")

local test = {}

local scroll_state = {}
local scroll_direction = "vertical"
local max_length = 100
local length = 0
local num_of_rects = 1
local area_bounds = {}
local disable_interaction = true
local actually_drawn_rect_count = 0

function test.layout()
    -- disable interaction if required
    local old = layers.allow_interaction
    if disable_interaction then
        layers.allow_interaction = false
    end
    -- scroll area with a number of rectangles inside
    scroll.start(scroll_state, scroll_direction, max_length)
    state.width = 100
    state.height = 100
    local start = scroll_direction == "vertical" and state.y or state.x
    actually_drawn_rect_count = 0
    for i in scroll.elements_in_view(110, num_of_rects) do
        if scroll_direction == "vertical" then
            state.y = start + 110 * (i - 1)
        elseif scroll_direction == "horizontal" then
            state.x = start + 110 * (i - 1)
        end
        rectangle()
        actually_drawn_rect_count = actually_drawn_rect_count + 1
    end
    if num_of_rects then
        length = num_of_rects * 110 - 10
    else
        length = math.huge
    end
    local bounds = area.get_bounds()
    scroll.done()
    -- copy bounds in case a new area gets onto the same position on the stack later
    area_bounds.left = bounds.left
    area_bounds.top = bounds.top
    area_bounds.right = bounds.right
    area_bounds.bottom = bounds.bottom
    -- reenable interaction if it was enabled
    layers.allow_interaction = old
end

test.sequence = coroutine.create(function()
    -- should not be scrollable yet, so cutout should be nil
    assert(scroll_state.cutout.left == nil, "cutout not nil despite not scrollable")
    assert(scroll_state.cutout.top == nil, "cutout not nil despite not scrollable")
    assert(scroll_state.cutout.right == nil, "cutout not nil despite not scrollable")
    assert(scroll_state.cutout.bottom == nil, "cutout not nil despite not scrollable")
    -- make scrollable by making content larger
    num_of_rects = 2
    coroutine.yield() -- wait a frame
    -- should be scrollable now so cutout should be set
    assert(scroll_state.cutout.left ~= nil, "cutout nil despite scrollable")
    assert(scroll_state.cutout.top ~= nil, "cutout nil despite scrollable")
    assert(scroll_state.cutout.right ~= nil, "cutout nil despite scrollable")
    assert(scroll_state.cutout.bottom ~= nil, "cutout nil despite scrollable")
    -- height should be smaller than the stacked rectangles
    assert(area_bounds.bottom - area_bounds.top < length, "area height should be smaller than contents")
    -- in fact it should correspond to max length
    assert(area_bounds.bottom - area_bounds.top == max_length, "area height should be max length")
    local overflow = length - max_length
    local scrollbar_size = math.max(max_length ^ 2 / length, 40) -- min scrollbar size is 40
    assert(scroll_state.scrollbar.bottom == scrollbar_size + scroll_state.scrollbar.top, "scrollbar size is wrong")
    local top_when_0 = scroll_state.scrollbar.top
    for i = 0, length - max_length do
        -- set directly, interaction should be tested elsewhere
        scroll_state.position = i
        -- disable interaction temporarily, otherwise user could scroll away and fail test
        disable_interaction = true
        coroutine.yield()
        disable_interaction = false
        -- check scrollbar position
        assert(scroll_state.scrollbar.top == top_when_0 + scroll_state.position * (max_length - scrollbar_size) / overflow, "scrollbar position does not match scroll position")
    end

    -- change direction
    scroll_direction = "horizontal"
    scroll_state.position = 0
    coroutine.yield()
    -- width should be smaller than the stacked rectangles
    assert(area_bounds.right - area_bounds.left < length, "area width should be smaller than contents")
    -- in fact it should correspond to max length
    assert(area_bounds.right - area_bounds.left == max_length, "area width should be max length")
    overflow = length - max_length
    scrollbar_size = math.max(max_length ^ 2 / length, 40) -- min scrollbar size is 40
    assert(scroll_state.scrollbar.right == scrollbar_size + scroll_state.scrollbar.left, "scrollbar size is wrong")
    local left_when_0 = scroll_state.scrollbar.left
    for i = 0, length - max_length do
        -- set directly, interaction should be tested elsewhere
        scroll_state.position = i
        -- disable interaction temporarily, otherwise user could scroll away and fail test
        disable_interaction = true
        coroutine.yield()
        disable_interaction = false
        -- check scrollbar position
        assert(scroll_state.scrollbar.left == left_when_0 + scroll_state.position * (max_length - scrollbar_size) / overflow, "scrollbar position does not match scroll position")
    end

    -- infinite scroll
    num_of_rects = nil
    -- scroll a lot
    for i = 0, 240 do
        scroll_state.position = i * 10
        coroutine.yield()
        assert(actually_drawn_rect_count <= 4, "More rects drawn than could possibly be needed to fit view")
    end
    -- go back
    for i = 240, 0, -1 do
        scroll_state.position = i * 10
        coroutine.yield()
        assert(actually_drawn_rect_count <= 4, "More rects drawn than could possibly be needed to fit view")
    end
end)

return test
