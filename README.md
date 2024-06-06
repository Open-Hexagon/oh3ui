# Introduction
This GUI Framework is made with simplicity in both usage and implementation in mind.
It is also made to work well with games.
To achieve these goals I chose to make an immediade mode GUI.
## Basic Example
The difference of an immediade mode GUI to a normal retained mode GUI is easy to understand.
Look at this bit of html and javascript that creates a button that prints something when pressed.
```html
<!DOCTYPE html>
<html>
  <head>
    <script src="myscript.js"></script>
  </head>
  <body>
    <button id="btn">Press me!</button>
  </body>
</html>
```
```javascript
document.getElementById("btn").onclick = () => {
  console.log("I was pressed!")
}
```
Here the layout is defined once initially in the html. It is then preserved until some javascript changes it.
Javascript only gets executed at loading time (script tag at the top) or with an event (e.g. a click) that calls a registered callback.
This type of GUI is called retained mode.
In an immediate mode framework the same example could look like this:
```lua
local button = require("ui.element.button")
local state = require("ui.state")

return function()
    state.width = 100
    state.height = 50
    button("Press me!")
    if state.clicked then
        print("I was pressed!")
    end
end
```
The ui may draw and update the menu using the function like so:
```lua
local mymenu = require("mymenu")
local ui = require("ui")

function love.run()
    return function()
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                return 0
            end
            ui.process_event(name, a, b, c, d, e, f)
        end
        if love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(0, 0, 0, 1)
            ui.start()
            mymenu()
            ui.done()
            love.graphics.present()
        end
        love.timer.step()
    end
end
```
All following examples will assume that this kind of mainloop calling the menu is already in place.

Now let's take that apart:
1. `state.width` and `state.height` are set. These values determine the width and height of any element placed on the screen. They may be changed between calls to allow for differently sized elements. (Note that `state.x` and `state.y` does the same for the position, however it is initialized as 0 0 by default so I am not setting it here)
```lua
state.width = 100
state.height = 50
```
2. Draw the button and update interaction values such as `state.clicked` or `state.hovering`. (Note that `button` actually takes another parameter, see [State](#State))
```lua
button("Press me!")
```
3. Check if `state.clicked` is true. If so print "I was pressed!"
```lua
if state.clicked then
    print("I was pressed!")
end
```

So as you can see in an immediate mode GUI the layout as well as the interaction is updated every single frame.

This may sound counterintuitive from a performance perspective, but GPUs are actually optimized to redraw everything every frame and sdl which löve2d is based on also expects the user to redraw the whole window every frame.

## Wrap layout example
Now the other part that is done every frame is the layout. As it is calculated every frame it shouldn't take long to do so while still being very flexible. So let's demonstrate that with another example.

A more complex layout in web development is a wrapping flexbox container which is basically just a row of elements that wrap into the next line when the width isn't sufficient anymore. This is used for responsive layouting a lot.
Here is how that looks:
```html
<!DOCTYPE html>
<html>
  <style>
    .myflex {
      display: flex;
      flex-direction: row;
      flex-wrap: wrap;
    }
    .rectangle {
      width: 100px;
      height: 50px;
      background-color: red;
      padding-right: 10px;
      padding-bottom: 10px;
    }
  </style>
  <body>
    <div class="myflex">
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
      <div class="rectangle"></div>
    </div>
  </body>
</html>
```
In my immediate mode GUI it looks like this:
```lua
local state = require("ui.state")
local rectangle = require("ui.rectangle")
local theme = require("ui.theme")
local ui = require("ui")

local red = { 1, 0, 0, 1 }

return function()
    state.width = 100
    state.height = 50
    for _ = 1, 10 do
        theme.rectangle_color = red
        rectangle()
        theme.rectangle_color = nil

        -- draw next element 10 to the right of this one
        state.x = state.x + state.width + 10

        -- calculate the x value of the right side of the rectangle that would be drawn in the next iteration
        local new_outer_x = state.x + state.width

        if new_outer_x > ui.get_width() then
            -- next rectangle would no longer be within the bounds of the screen
            -- wrap into next line by resetting x to 0
            state.x = 0
            -- and moving down in y with a padding of 10
            state.y = state.y + state.height + 10
        end
    end
end
```
Let's take that apart:
1. width and height is initialized again. And again note that x and y is initialized at 0 0 every frame.
```lua
state.width = 100
state.height = 50
```
2. loop 10 times to draw 10 rectangles. Note that I could draw a different amount of rectangles every frame without any real performance penalty. A retained mode GUI would have to recalculate the layout at this point which is often quite expensive.
```lua
for _ = 1, 10 do
    ...
end
```
Now all further steps happen for each iteration

3. Draw the rectangle with a red color and update its interaction state. Setting `theme.rectangle_color` to nil is just going to reset it to default rectangle color (red is defined above the function as to not allocate a new table every frame.)
```lua
theme.rectangle_color = red
rectangle()
theme.rectangle_color = nil
```
4. The anchor (see [Anchor](#Anchor)) is initialized so that x and y represent the top left corner of the element, so if you want to change the position in such a way that the next element is to the right of this one with a gap of 10 in between. You just add the width of the current element + 10.
```lua
-- draw next element 10 to the right of this one
state.x = state.x + state.width + 10
```
5. Now to detect if the next element is going to fit in the bounds the outermost x position of the next element is calculated by just adding the width to the current x position. This position is then compared to our maximum width, in this case the whole width available to the UI.
```lua
-- calculate the x value of the right side of the rectangle that would be drawn in the next iteration
local new_outer_x = state.x + state.width

if new_outer_x > ui.get_width() then
    ...
end
```
6. Now only if the last step detected that the next element is not going to fit, the position is set to start again from the left but in the next line now.
```lua
-- next rectangle would no longer be within the bounds of the screen
-- wrap into next line by resetting x to 0
state.x = 0
-- and moving down in y with a padding of 10
state.y = state.y + state.height + 10
```

With this demonstration you can tell that even complex layouts can be achieved with a very simplistic way of positioning elements. And thanks to it happening every frame, no matter what causes the size of the UI to change it'll immediately respond in the next frame without any drops in the performance.

## Alignement
### Anchor
The anchor is set using `state.anchor.x` and `state.anchor.y` it is initialized at 0 0 every frame.
These values are factors from 0 to 1. (could set it outside the range but that doesn't really make any sense.)
They determine how far the element is moved from the position where it would be if x and y correspond to the top left corner.

So an anchor of 1 and 1 would move it left and up exactly by its own width and height which causes the x and y position to correspond to the bottom right corner.
Similarly 1 and 0 would correspond to the top right corner and 0 and 1 to the bottom left one.

Now the interesting part is that you can also use values between 0 and 1 e.g. 0.5.
A value of 0.5 would move it by half its width/height, so an anchor of 0.5 and 0.5 would result in x and y corresponding to the center of the element.
### Text
Löve has its own options for text, these are exposed through `state.text_wraplimit` and `state.text_align`.

Wraplimit does what you'd expect, it wraps the text if its width becomes greater than the specified amount.

Text align is either "left", "center" or "right" and aligns the text (including wrapped lines) to the width given by `state.width` this means that it may have unexpected results if used together with anchor or auto resizing.

Auto resizing is something that certain elements e.g. labels do to set `state.width` and `state.height` to their own values, which is useful for e.g. drawing a rectangular border around text. However this is sometimes not wanted so it can be disabled by setting `state.allow_automatic_resizing` to false

## State
All previous examples have been fully stateless. However any sufficiently advanced GUI has to have state to e.g. store for how long the user has been hovering a button for an animation or where the current scroll position is etc.

In C many imguis do this by passing a reference to an often local static variable (In c one can define a variable inside a function that keeps its value across function calls using the static keyword).

Now lua does not allow us to get the reference of any variable. However we have a very versatile type that is always passed by reference: the table.

So to actually make the inital button example functional we pass a table where the button can store its state
(specifically it stores information about hover time to animate a color change as the user is hovering the button)
```lua
local button = require("ui.element.button")
local state = require("ui.state")

local button_state = {}

return function()
    state.width = 100
    state.height = 50
    button(button_state, "Press me!")
    if state.clicked then
        print("I was pressed!")
    end
end
```

Writing the state variables at the top like this all the time is a bit annoying. So to simplify that one could write an Id system like this:
```lua
local id_state_table = {}

function Id(key)
    id_state_table[key] = id_state_table[key] or {}
    return id_state_table[key]
end
```
Now instead of defining button state at the top we could write `Id("mybuttonid")` whereever we need it. So `button(button_state, "Press me!")` would become `button(Id("mybuttonid"), "Press me!")`.
While this approach works fine, it may have a probably negligible performance overhead due to calling this function everywhere and it doesn't look particularly beautiful.

Luckily lua has a different option to do something like this for us: metatables.
This is the code you can find in `ui/id_table.lua`
```lua
local meta = {
    __index = function(t, k)
        t[k] = {}
        return t[k]
    end
}

---create a new table that initializes any unknown key as empty table
return function()
    return setmetatable({}, meta)
end
```
It does exactly the same thing as before, but now the table returned from `require("ui.id_table")()` automatically initializes any keys that it doesn't have yet with an empty table.
So instead of typing `Id("mybuttonid")` we can type `id_table.mybuttonid`.

The initialization with an empty table happens in the `__index` function of the metatable which is only called if the key doesn't exist in the original table, so the negligible performance overhead is gone as well as subsequent accesses will no longer call the function.

## Custom elements
One thing I have not yet touched on is how easy it is to define a new element in an imgui like this.
This is the code for the rectangle element.
```lua
local state = require("ui.state")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")

---rectangle element
---@param mode string? "fill" or "line" (default is "fill")
return function(mode)
    state.update()
    draw_queue.rectangle(mode or "fill", state.left, state.top, state.right, state.bottom, theme.rectangle_color)
end
```
There are really only 2 things happening here when it is called.
1. `state.update` is called which updates the interaction states for the element and also calculates the bounds (left, top, right, bottom) of the element using x, y, width, height and anchor as input.
2. The rectangle is drawn. (Note that all draw operations are actually queued but more on that implementation detail later)

In a traditional retained mode GUI you couldn't just define a function like this, you'd need to define a new class that inherits from some kind of base element class and implements certain event handlers and draw functions.

## Areas
This GUI system does not have containers. The hierarchy they introduce may make a lot of sense on a logical level is in my opinion however not actually required, especially for a game ui, and makes the implementation of the system more complex which usually results in the usage being harder to understand as well. By making the implementation more complex I am talking about things like recursive layout calculation and event propagation and bubbling.

But somehow we still need some form of functionality to group elements together, to e.g. make a part of the screen scrollable or to make a background exactly as large as its contents.
This is where the area system comes into play. Think of an area not as a container but as its own thing that just bases itself on the aligned rectangular area that perfectly fits around a set of elements that is still absolutely positioned on the screen.

### Background
The simplest area is probably the background area, all it does is draw a rectangle behind a set of elements.
Now let's look at a simple example:
```lua
local background_area = require("ui.area.background")
local rectangle = require("ui.element.rectangle")
local state = require("ui.state")

local red = { 1, 0, 0, 1 }

return function()
    state.width = 100
    state.height = 50

    background_area.start()

    rectangle()
    
    state.x = state.x + state.width + 10
    rectangle()

    theme.rectangle_color = red
    background_area.done()
    theme.rectangle_color = nil

    state.x = state.x + state.width + 10
    rectangle()
end
```

1. width and height are initialized with 100 and 50 again.
```lua
state.width = 100
state.height = 50
```
2. the background area is started. Any element that is created now will update the bounds of the area.
```lua
background_area.start()
```
3. create two rectangles with a gap of 10.
```lua
rectangle()

state.x = state.x + state.width + 10
rectangle()
```
4. end the background area, any following elements will no longer update its bounds. The rectangle color is set to red for this as the area uses it to insert the draw command for the background into the draw queue before the elements are drawn, so that it is actually behind them. This is why draw commands have to be queued, because the background area cannot know the bounds it's going to have when start is called.
```lua
theme.rectangle_color = red
background_area.done()
theme.rectangle_color = nil
```
5. draw another rectangle outside the background area with a gap of 10 to the last one
```lua
state.x = state.x + state.width + 10
rectangle()
```

### Scroll
Scroll areas work in a very similar way, the difference being that it needs some parameters.
This is the same example as last time except with a horizontal scroll area rather than a background (note that areas can be nested so you can have both).
```lua
local rectangle = require("ui.element.rectangle")
local scroll_area = require("ui.area.scroll")
local ids = require("ui.id_table")()
local state = require("ui.state")

return function()
    state.width = 100
    state.height = 50

    scroll_area.start(ids.example_scroll, "horizontal", 150)

    rectangle()
    
    state.x = state.x + state.width + 10
    rectangle()

    scroll_area.done()

    state.x = state.x + state.width + 10
    rectangle()
end
```
The `scroll_area.start` function takes a table for persisted scroll state as first parameter where it'll store things like the current scroll position. The next one takes either "vertical" or "horizontal" which determines which direction it is scrollable in. (nest two scroll areas to allow scrolling in both directions.) The last parameter determines the length (in width/height depending on scroll direction) after which the area is supposed to become scrollable.

Note that elements are still absolutely positioned even if they are cut off by the scroll area, so any subsequent elements like the last rectangle in this example will still position themselves as if the scroll area didn't exist but only its contents.

If this is not desired the position of the next element could be based off of the area bounds like so:
```lua
local rectangle = require("ui.element.rectangle")
local scroll_area = require("ui.area.scroll")
local ids = require("ui.id_table")()
local state = require("ui.state")
local area = require("ui.area")

return function()
    state.width = 100
    state.height = 50

    scroll_area.start(ids.example_scroll, "horizontal", 150)

    rectangle()
    
    state.x = state.x + state.width + 10
    rectangle()

    local scroll_area_bounds = area.get_bounds()
    scroll_area.done()

    state.x = scroll_area_bounds.right + 10
    rectangle()
end
```
Note that `area.get_bounds()` has to be called before `scroll_area.done()` as it gets the bounds of the uppermost area on the stack.

Also note that the bounds may be modified before the `.done()` call to e.g. add padding to the area. Here's a snippet that adds a padding of 4.
```lua
local bounds = area.get_bounds()
bounds.left = bounds.left - 4
bounds.top = bounds.top - 4
bounds.right = bounds.right + 4
bounds.bottom = bounds.bottom + 4
```

### Collapse
Now if you don't want to scroll but just cut elements off e.g. for an animation. This area is what you'd use.
Let's modify the same example again:
```lua
local rectangle = require("ui.element.rectangle")
local collapse_area = require("ui.area.collapse")
local ids = require("ui.id_table")()
local state = require("ui.state")
local area = require("ui.area")

return function()
    state.width = 100
    state.height = 50

    collapse_area.start()

    rectangle()
    
    state.x = state.x + state.width + 10
    rectangle()

    local bounds = area.get_bounds()

    local animation_factor = (math.sin(love.timer.getTime() * 5) + 1) * 0.5
    collapse_area.done(animation_factor)

    state.x = state.x + 10
    rectangle()
end
```
The only really interesting part here is `collapse_area.done` it receives 2 parameters, a width- and height factor. It is a value from 0 to 1 where 0 shows nothing and 1 shows everything and in between the contents are cut off. As we only pass something to the width factor here, the contents are only cut off in width.

### Custom areas
Again I want to show that even the implementation part of this framework is very simple. Even an area like this is quite trivial to implement yourself.
For example this is the background area implementation:
```lua
local area = require("ui.area")
local theme = require("ui.theme")
local draw_queue = require("ui.draw_queue")
local background = {}

---start a background area
function background.start()
    area.start()
    -- put background draw here once bounds are known
    draw_queue.placeholder()
end

---draw the area background and the contents on top
function background.done()
    local bounds = area.get_bounds()
    area.done()
    draw_queue.put_next_in_last_placeholder()
    draw_queue.rectangle("fill", bounds.left, bounds.top, bounds.right, bounds.bottom, theme.rectangle_color)
end

return background
```
Let's look at that in more detail
1. when the area is started it calls `area.start` which internally puts the area on the stack and starts updating its bounds whenever elements are created.
```lua
area.start()
```
2. It also inserts a placeholder in the draw queue, it can be filled with a draw command later. This draw command will then be in front of the ones of the content of the area. This prevents actual inserting from happening in the draw queue which would require draw commands to be moved in the queue which simplifies the implementation of the draw queue and may even bring a negligible performance benefit.
```lua
draw_queue.placeholder()
```
3. when the area is done, it first gets the bounds it calculated from the contents and then calls `area.done` which removes the area from the stack
```lua
local bounds = area.get_bounds()
area.done()
```
4. the placeholder that was put into the draw queue earlier is filled with a draw command for a rectangle that spans the bounds of the area using the rectangle color.
```lua
draw_queue.put_next_in_last_placeholder()
draw_queue.rectangle("fill", bounds.left, bounds.top, bounds.right, bounds.bottom, theme.rectangle_color)
```

## Layering
To layer multiple elements on top of each other one could naively just put one there after the other one. The problem is that interaction will still be processed for both elements, with the bottom one being first. This is why a layering system is required.

To use it first replace the
```lua
ui.start()
mymenu()
ui.done()
```
in your draw code with
```lua
local layers = require("ui.layers")
...
ui.start()
layers.run()
ui.done()
```

Then to actually draw a menu, you call `layers.push` with the function that draws the menu on startup. The interesting part now is that you can call `layers.push` in your menu as well for example if a button is clicked. It does not replace the menu (call `layers.pop` and then `layers.push` if this is desired) but draws the new one on top of the old one which is then no longer interactable.

To close the overlay you can call `layers.pop` which will then go back to the last menu.
