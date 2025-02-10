---A module that gathers mouse related events and displays them in a nice way.
---For checking mouse intersection: see sensor/init.lua

local events = require("ui.events")
local cursor = require("ui.cursor")
local placement = cursor.placement
local extmath = require("ui.extmath")
local mask = require("ui.mask")

local mouse_navigation = {
    -- this frame's mouse position
    x = -1,
    y = -1,

    -- this frame's mouse position (screen coordinates)
    screen_x = -1,
    screen_y = -1,

    -- change in coordinates from last frame (not screen coordinates)
    dx = 0,
    dy = 0,

    -- wheel movement
    wheel_dx = 0,
    wheel_dy = 0,

    clicked = nil,
    holding = nil,
    dragging = nil,
    started_dragging = nil,
    stopped_dragging = nil,

    -- press location (not screen coordinates)
    drag_origin_x = nil,
    drag_origin_y = nil,
}

---Center of the bubble that decides whether the cursor has moved too much.
---Uses screen coordinates since we don't want the bubble changing size based on UI scaling.
local press_bubble_x, press_bubble_y
local press_bubble_radius = 6

---@param event_name string
local function event_filter(event_name)
    return string.match(event_name, "mouse[prm]") or event_name == "wheelmoved"
end

---Update mouse output. Should be run at the start of a frame.
function mouse_navigation.evaluate()
    -- Get mouse positions
    mouse_navigation.screen_x, mouse_navigation.screen_y = love.mouse.getPosition()
    mouse_navigation.x, mouse_navigation.y =
        love.graphics.inverseTransformPoint(mouse_navigation.screen_x, mouse_navigation.screen_y)

    mouse_navigation.dx, mouse_navigation.dy = 0, 0
    mouse_navigation.wheel_dx, mouse_navigation.wheel_dy = 0, 0

    -- these fields only survive for 1 frame
    mouse_navigation.clicked = nil
    mouse_navigation.started_dragging = nil
    mouse_navigation.stopped_dragging = nil

    -- evaluate global hold/click/drag behavior from mouse events
    -- record mouse and wheel movement
    for event in events.iterate(event_filter) do
        local name, x, y, a, b, c = unpack(event)

        if name == "wheelmoved" then
            -- Record wheel movement
            mouse_navigation.wheel_dx = mouse_navigation.wheel_dx + x
            mouse_navigation.wheel_dy = mouse_navigation.wheel_dy + y
        elseif name == "mousemoved" then
            local dx, dy, istouch = a, b, c

            -- Transition from clicking to dragging if mouse moves too far
            -- Using L1 distance, so the bubble is not actually a circle, it's a diamond <>.
            if
                mouse_navigation.holding
                and math.abs(press_bubble_x - mouse_navigation.screen_x)
                        + math.abs(press_bubble_y - mouse_navigation.screen_y)
                    >= press_bubble_radius
            then
                -- start dragging
                mouse_navigation.started_dragging = mouse_navigation.holding
                mouse_navigation.dragging = mouse_navigation.holding
                mouse_navigation.drag_origin_x = mouse_navigation.x
                mouse_navigation.drag_origin_y = mouse_navigation.y
                -- stop holding
                mouse_navigation.holding = nil
            end

            -- Record mouse movement
            -- Using the event dx, dy happens to work better if the mouse is being repositioned manually.
            mouse_navigation.dx, mouse_navigation.dy = love.graphics.inverseTransformPoint(dx, dy)
        else
            local button_id, istouch, presses = a, b, c

            if name == "mousepressed" then
                if mouse_navigation.holding then
                    -- Pressing another button while holding stops holding
                    mouse_navigation.holding = nil
                elseif mouse_navigation.dragging then
                    -- Pressing another button while dragging stops dragging
                    mouse_navigation.stopped_dragging = mouse_navigation.dragging
                    mouse_navigation.dragging = nil
                else
                    -- Pressing a button while not already holding or dragging starts holding
                    mouse_navigation.holding = button_id
                    press_bubble_x = mouse_navigation.screen_x
                    press_bubble_y = mouse_navigation.screen_y
                end
            elseif name == "mousereleased" then
                if mouse_navigation.holding then
                    -- Releasing the same button that is being held is a click. If not then holding is stopped.
                    if button_id == mouse_navigation.holding then
                        mouse_navigation.clicked = button_id
                    end
                    mouse_navigation.holding = nil
                elseif mouse_navigation.dragging then
                    -- Releasing a button while dragging stops dragging
                    mouse_navigation.stopped_dragging = mouse_navigation.dragging
                    mouse_navigation.dragging = nil
                end
            end
        end
    end
end

---@type boolean?
local is_hovering

local function invalidate_hovering_cache()
    is_hovering = nil
end

cursor.register_on_placement_change_hook(invalidate_hovering_cache)
mask.register_on_mask_change_hook(invalidate_hovering_cache)

local function calculate_is_hovering()
    if mouse_navigation.dragging then
        return false
    end

    -- we want to use the placement table since it contains literal element locations
    local left, top, right, bottom = mask.get()

    if left then
        ---@cast left number
        ---@cast top number
        ---@cast right number
        ---@cast bottom number
        left, top, right, bottom = extmath.aligned_rectangle_intersection(
            placement.left,
            placement.top,
            placement.right,
            placement.bottom,
            left,
            top,
            right,
            bottom
        )
    else
        left, top, right, bottom = placement.left, placement.top, placement.right, placement.bottom
    end

    if left then
        return extmath.point_in_aligned_rectangle(mouse_navigation.x, mouse_navigation.y, left, top, right, bottom)
    end

    return false
end

---Gets whether the mouse is hovering the current placement.
---@return boolean
---@nodiscard
function mouse_navigation.is_hovering()
    if is_hovering == nil then
        is_hovering = calculate_is_hovering()
    end
    return is_hovering
end

---Gets the mouse button that is holding the current placement.
---(This is not the same as checking the `mouse_navigation.clicked` field directly.)
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_holding()
    if mouse_navigation.is_hovering() then
        return mouse_navigation.holding
    end
    return nil
end

---Gets the mouse button that clicked the current placement.
---(This is not the same as checking the `mouse_navigation.clicked` field directly.)
---@return mouse_button?
---@nodiscard
function mouse_navigation.get_clicked()
    if mouse_navigation.is_hovering() then
        return mouse_navigation.clicked
    end
    return nil
end

return mouse_navigation
