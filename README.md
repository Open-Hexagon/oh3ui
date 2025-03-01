# Introduction
A more advanced immediate mode GUI that focuses more on ease of usage with minimal compromises on functional accuracy, at the cost of some implementation simplicity.

## Major differences

### Cursor
Formerly known as state, the cursor is now much more powerful. It's behavior in relation to placing elements is now more precicely defined. The cursor can also save snapshots of itself in a stack and revert back to them later. This stack has some other uses too. There are also many new helper functions to make layout easier.

### Area
Area is now a part of the cursor module. It's now merely another cursor helper function.

### Mask
The functionality of scissor stack and area cutouts have been merged. Masking will now affect both draw operations and mouse detection. This required the mouse detection to happen after the draw queue runs which causes mouse detection information to be delayed by one frame. This isn't really a problem though.

### Mouse detection
Mouse detection is now accurate and reflects the behavior of real GUIs. Proper Z-layering is implemented, so overlapping mouse detection regions are handled properly. This comes along with new invisible sensor elements so mouse detection regions can be precisely calculated.

### UI Scaling
UI scaling is now perfectly accurate (with a few minor exceptions). There's no need to pass every coordinate point through `transformPoint` anymore. This came with the loss of some features such as element rotation.

### Scrolling
Scrolling is very different now. All of it's functionality is contained in one monolithic file. Whether it's better or worse than the old version remains to be seen. (I actually never figured out how the older version worked.)

## Feature Compromises
Features that will not be implemented to make development of the UI system easier.

- There will be no system to backpropagate the size of elements. If something doesn't fit where it needs to go, it will have to either spill out of bounds or get cut off. It is up to the developer to ensure that there is enough space for elements or make special cases when elements can't fit.
- There will be no universal method to get the size of an element before it gets rendered. Dear ImGui doesn't do this so why should ours? 

## Requirements

1. A draw queue that can be built out-of-order.
   1. Out-of-order building is achived with reservations
      1. Draw queue slots can be reserved and filled in later.
      2. Multiple reservations can be made at a time which can be filled in-order.
      3. Reservations take on the location of the placement: **\[when the reservation was taken\]** / when the reservation was made.
2. Recording keyboard and mouse navigation should not be put in state tables.
   1. This creates too many state tables
   2. The same functions to get mouse/keyboard navigation outputs should be used everywhere.
      1. These functions will only be accurate to the latest created placement/cell, respectively.
3. Mouse navigation should be done during a frame?
   1. I mean should it? Keyboard navigation doesn't do this.
   2. *We could leverage the cell ids that keyboard navigation uses to help with mouse navigation as well.*
4. A cursor which can be used to align and place elements.
   1. Support elements that don't fit the cursor.
   2. Cursor can be set to auto-reshape which will reshape itself to exactly surround an element that doesn't fit the cursor. 
   3. Support translating elements (no rotating).
   4. Cursor shall be agnostic to any external factors such as UI scale. 
5. Elements can be masked which cuts off drawing and mouse interaction.
   1. Masking should work even if the cursor is translated.
   2. To satisfy requirement 2, masking operations cannot take reservations. They must be called in order.
      1. Doing this comes with a caveat though:
         ```
         Don't take a reservation that came before any newly made scissor operation.
         This makes an element think it has the new scissor, but it will get drawn using the previous scissor which probably isn't what you want! 
         
         i.e. Don't do this:
            make reservation 1
            push scissor
            take reservation 1
         
         This is okay though:
            make reservation 1
            push scissor
            ...
            pop scissor
            take reservation 1
         ```

6. Checking for clicking and keyboard should work for entire elements, even after they're created. For example, this should work as you'd expect:
   ```lua
   button("a button")
   if m_nav.get_clicked() or kb_nav.get_action() then
      print("button clicked")
   end
   ``` 
   1. For more complex elements with multiple interactable regions, it should behave as if the entire element is one whole button.
7. Mouse dragging needs some way to know which specific element it is dragging. It can't just be what's under the mouse.
   1. Still not sure how to go about this yet. (With keyboard navigation, this is easy since every element gets it's own cell id.)
8. Sub-elements?
   1. You can call elements inside of other elements.
   2. Actually... probably remove this.
