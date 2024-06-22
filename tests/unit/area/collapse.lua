local collapse = require("ui.area.collapse")
local rectangle = require("ui.element.rectangle")
local state = require("ui.state")
local area = require("ui.area")
local ui = require("ui")

local test = {}

local collapse_state = {}
local area_bounds = {}

function test.layout()
    -- collapse area with a number of rectangles inside
    collapse.start(collapse_state)
    state.width = 100
    state.height = 100
    rectangle()
    local bounds = area.get_bounds()
    collapse.done()
    -- copy bounds in case a new area gets onto the same position on the stack later, also convert to screen space
    area_bounds.left, area_bounds.top = love.graphics.transformPoint(bounds.left, bounds.top)
    area_bounds.right, area_bounds.bottom = love.graphics.transformPoint(bounds.right, bounds.bottom)
end

test.sequence = coroutine.create(function()
    -- should not be cut off yet, so cutout should match content bounds
    assert(collapse_state.cutout.left == area_bounds.left, "cutout not matching content despite not cut off")
    assert(collapse_state.cutout.top == area_bounds.top, "cutout not matching content despite not cut off")
    assert(collapse_state.cutout.right == area_bounds.left + 100 * ui.scale, "cutout not matching content despite not cut off")
    assert(collapse_state.cutout.bottom == area_bounds.top + 100 * ui.scale, "cutout not matching content despite not cut off")
    -- limit area in width, try multiple factors
    for fac = 0, 99 do
        collapse_state.width_factor = fac / 100
        coroutine.yield() -- wait a frame
        -- should be cut off now, so cutout should no longer match content in width
        assert(collapse_state.cutout.left == area_bounds.left, "cutout wrong")
        assert(collapse_state.cutout.top == area_bounds.top, "cutout wrong")
        assert(collapse_state.cutout.right ~= area_bounds.left + 100 * ui.scale, "cutout still matching content in width despite factor not 1")
        assert(collapse_state.cutout.bottom == area_bounds.top + 100 * ui.scale, "cutout wrong")
        -- width should be smaller than rectangle
        assert(area_bounds.right - area_bounds.left < 100 * ui.scale, "area width should be smaller than contents")
        -- in fact it should correspond to content width * width factor
        assert(area_bounds.right == area_bounds.left + 100 * ui.scale * collapse_state.width_factor, "area width should match content width * width factor")
    end

    -- change direction and do the same again
    collapse_state.width_factor = nil
    for fac = 0, 99 do
        collapse_state.height_factor = fac / 100
        coroutine.yield()
        -- should be cut off now, so cutout should no longer match content in height
        assert(collapse_state.cutout.left == area_bounds.left, "cutout wrong")
        assert(collapse_state.cutout.top == area_bounds.top, "cutout wrong")
        assert(collapse_state.cutout.right == area_bounds.left + 100 * ui.scale, "cutout wrong")
        assert(collapse_state.cutout.bottom ~= area_bounds.top + 100 * ui.scale, "cutout still matching content in height despite factor not 1")
        -- height should be smaller than content
        assert(area_bounds.bottom - area_bounds.top < 100 * ui.scale, "area height should be smaller than contents")
        -- in fact it should correspond to content height * height factor
        assert(area_bounds.bottom == area_bounds.top + 100 * ui.scale * collapse_state.height_factor, "area width should match content height * height factor")
    end
end)

return test
