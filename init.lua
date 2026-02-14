local super_modname = ...

---custom loader that only looks for files inside this folder
---@param modname string
---@return function
local function loader(modname)
    local error_str = ""

    local super_modname_path = super_modname:gsub("%.", "/")
    local modname_path = modname:gsub("%.", "/")

    local path1 = string.format("%s/%s/%s.lua", love.filesystem.getSource(), super_modname_path, modname_path)
    local path2 = string.format("%s/%s/%s/init.lua", love.filesystem.getSource(), super_modname_path, modname_path)

    local chunk = loadfile(path1)
    if not chunk then
        error_str = error_str .. string.format("\n\t[ohui internal error] no file '%s'", path1)
        chunk = loadfile(path2)
        if not chunk then
            error_str = error_str .. string.format("\n\t[ohui internal error] no file '%s'", path2)
            return error_str
        end
    end

    return chunk
end

-- do some package trickery to make require only search within this folder

local old_package_loaded = package.loaded
local old_package_loaders = package.loaders

package.loaded = {}
package.loaders = { package.loaders[1], loader }

---ui api endpoints

local events = require("ui.events")
local layer = require("ui.layer")
local settings = require("ui.settings")
local draw_data = require("ui.draw_queue.draw_data")
local selection_outline = require("ui.decorator.element.selection_outline")
local draw_queue_draw = require("ui.draw_queue.draw")
local view_request_evaluate = require("ui.area.view_request").evaluate
local control_evaluate = require("ui.control.evaluate")
local tooltip = require("ui.decorator.element.tooltip")

---This red grid shows screen space
local function overlay_screen_grid()
    -- luacov: disable
    if not settings.overlay_grid then
        return
    end

    love.graphics.setLineWidth(2)
    love.graphics.setColor(1, 0, 0, 0.2)

    local width, height = love.graphics.getDimensions()

    local x = 0
    while x < width do
        love.graphics.line(x, 0, x, height)
        x = x + settings.overlay_grid
    end
    x = width
    love.graphics.line(x, 0, x, height)

    local y = 0
    while y < height do
        love.graphics.line(0, y, width, y)
        y = y + settings.overlay_grid
    end
    y = height
    love.graphics.line(0, y, width, y)
    -- luacov: enable
end

---This green grid shows scaled space.
---This is where drawn graphics end up, but not everything is affected by graphics transforms.
local function overlay_scaled_grid()
    -- luacov: disable
    if not settings.overlay_grid then
        return
    end

    love.graphics.setLineWidth(2)
    love.graphics.setColor(0, 1, 0, 0.2)

    local width, height = love.graphics.getDimensions()

    local x = 0
    while x < width do
        love.graphics.line(x, 0, x, height)
        x = x + settings.overlay_grid
    end
    x = width
    love.graphics.line(x, 0, x, height)

    local y = 0
    while y < height do
        love.graphics.line(0, y, width, y)
        y = y + settings.overlay_grid
    end
    y = height
    love.graphics.line(0, y, width, y)

    -- Show scaled mouse position
    x, y = love.mouse.getPosition()
    love.graphics.transformPoint(x, y)
    love.graphics.circle("line", x, y, 4)
    -- luacov: enable
end

---Runs the ui. Must be called every frame
local function run()
    do -- prepare
        overlay_screen_grid()
        -- scale immediately so that screen space positions can be accounted for in any transforms and inverseTransforms
        love.graphics.push()
        love.graphics.scale(settings.scale)
        overlay_scaled_grid()
    end

    do -- run
        layer.run_all()
        -- add the selection outline if it wasn't already done by any of the area elements
        selection_outline.add_to_queue()
    end

    do -- evaluate
        -- draw in order
        draw_data.bake_translations()
        draw_queue_draw()

        -- for auto-scrolling with keyboard nav
        view_request_evaluate()

        -- evaluate control methods
        control_evaluate()
    end

    do -- clean up
        layer.prepare_for_next_frame()
        tooltip.clean_up()
        selection_outline.clean_up()
        draw_data.clear()
        events.clear()
        love.graphics.pop()
    end
end

local ui = {
    -- only user facing api endpoints should be visible from this table

    ---Normal elements.
    element = {
        button = require("ui.element.button"),
        checkbox = require("ui.element.checkbox"),
        cycle_button = require("ui.element.cycle_button"),
        icon_button = require("ui.element.icon_button"),
        icon_cycle_button = require("ui.element.icon_cycle_button"),
        numeric_input = require("ui.element.numeric_input"),
        slider = require("ui.element.slider"),
        switch = require("ui.element.switch"),
        toggle_hex = require("ui.element.toggle_hex"),
        toggle = require("ui.element.toggle"),
    },

    ---Two-part area elements.
    area_element = {
        background = require("ui.area.element.background"),
        collapse = require("ui.area.element.collapse"),
        scroll = require("ui.area.element.scroll"),
    },

    ---Decorator elements.
    decorator = {
        selection_outline = require("ui.decorator.element.selection_outline").set_placement,
        tooltip = require("ui.decorator.element.tooltip").tooltip,
    },

    ---UI settings. These will live-update.
    settings = require("ui.settings"),

    ---Constants used by elements. Read-only.
    element_parameters = require("ui.element_conf"),

    ---Colors used by the UI + some handy related functions.
    theme = require("ui.theme"),

    ---Stack manager. Locks/unlocks the cursor_stack, translate_stack, area_stack, and aeb_stack to prevent changes.
    stack_manager = require("ui.stack_manager"),

    ---Area element balance stack. Can be used as a general purpose stack.
    aeb = require("ui.area.aeb"),

    ---Used to position and arrange elements.
    cursor = require("ui.cursor"),

    ---For drawing elements. The draw queue can be built out of order. Has some other uses.
    draw = require("ui.draw_queue"),

    ---For defining how to dontrol the UI.
    control = require("ui.control"),

    ---Functions for UI effects.
    effect = require("ui.effect"),

    ---Functions used to suppress certain element functionality.
    suppress = require("ui.suppress"),

    ---Makes id tables which can be used to store ui state
    new_id_table = require("ui.id_table"),

    ---UI layer controls.
    layer = {
        push = layer.push,
        pop = layer.pop,
        is_current_layer_active = layer.is_current_layer_active,
        get_current_layer = layer.get_current_layer,
    },

    ---Text utilities
    text = require("ui.text"),

    ---Core functions
    push_event = events.add,
    run = run,
}

package.loaded = old_package_loaded
package.loaders = old_package_loaders

return ui
