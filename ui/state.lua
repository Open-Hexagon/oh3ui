local hover_interaction = require("ui.interaction.hover")
local click_interaction = require("ui.interaction.click")

local state = {}

---reset manual state to default values
function state.reset()
    -- set manually
    state.x = 0
    state.y = 0
    state.width = 0
    state.height = 0
    -- x=0..1  0: left, 1: right
    -- y=0..1  0: top, 1: bottom
    state.anchor = { x = 0, y = 0 }
    state.font = "assets/OpenSquare.ttf"
    state.font_size = 32
    -- allow increasing element size automatically if too small
    state.allow_automatic_resizing = true

    -- updated automatically
    state.areas = state.areas or {}
    state.current_area_index = 0
    state.left = 0
    state.right = 0
    state.top = 0
    state.bottom = 0
    state.hovering = false
    state.clicked = false
end

state.reset()

---check if a screen space position is currently inside an interactive area
---@param x number
---@param y number
---@return boolean
function state.is_position_interactable(x, y)
    for i = 1, state.current_area_index do
        local area = state.areas[i]
        if area.extra_data.state and area.extra_data.state.cutout and area.extra_data.state.cutout.left then
            -- is scroll area
            if
                x < area.extra_data.state.cutout.left
                or x > area.extra_data.state.cutout.right
                or y < area.extra_data.state.cutout.top
                or y > area.extra_data.state.cutout.bottom
            then
                return false
            end
        end
    end
    return true
end

---update element's position, hover state and clicked state
function state.update()
    if state.allow_automatic_resizing then
        if state.auto_width then
            state.width = state.auto_width
        end
        if state.auto_height then
            state.height = state.auto_height
        end
    end
    state.auto_width = nil
    state.auto_height = nil

    -- get edges
    state.left = state.x - state.anchor.x * state.width
    state.top = state.y - state.anchor.y * state.height
    state.right = state.x + (1 - state.anchor.x) * state.width
    state.bottom = state.y + (1 - state.anchor.y) * state.height

    local mouse_x, mouse_y = love.mouse.getPosition()

    -- update area bounds
    if state.areas[state.current_area_index] then
        local bounds = state.areas[state.current_area_index].bounds
        bounds.left = bounds.left == nil and state.left or math.min(bounds.left, state.left)
        bounds.top = bounds.top == nil and state.top or math.min(bounds.top, state.top)
        bounds.right = bounds.right == nil and state.right or math.max(bounds.right, state.right)
        bounds.bottom = bounds.bottom == nil and state.bottom or math.max(bounds.bottom, state.bottom)
    end

    -- limit interaction area if scroll areas are on the area stack
    if not state.is_position_interactable(mouse_x, mouse_y) then
        state.hovering = false
        state.clicked = false
        return
    end

    -- convert mouse position to element space
    mouse_x, mouse_y = love.graphics.inverseTransformPoint(mouse_x, mouse_y)

    state.hovering = hover_interaction.check(mouse_x, mouse_y)

    -- click check
    state.clicked = state.hovering and click_interaction.clicking
end

local fonts = {}

---get the currently used font object
---@param scale_adjusted boolean?
---@return love.Font
function state.get_font(scale_adjusted)
    local file = state.font
    local size = state.font_size
    if scale_adjusted then
        size = size * math.floor(require("ui").scale * 100) / 100
    end
    fonts[file] = fonts[file] or {}
    local font = fonts[file][size]
    if not font then
        font = love.graphics.newFont(file, size)
        font:setFilter("nearest", "nearest")
        fonts[file][size] = font
    end
    return font
end

return state
