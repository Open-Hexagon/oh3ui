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
Mouse detection is now accurate and better reflects the behavior of real GUIs. Proper Z-layering is implemented, so overlapping mouse detection regions are handled properly. A special mouse sensor element is used to specify regions on the screen that can detect mouse input.

### UI Scaling
UI scaling is now perfectly accurate (with a few minor exceptions). There's no need to pass every coordinate point through `transformPoint` anymore. This came with the loss of some features such as element rotation.

### Scrolling
Scrolling is very different now. All of it's functionality is contained in one monolithic file. Whether it's better or worse than the old version remains to be seen. (I actually never figured out how the older version worked.)

## Feature Compromises
Features that will not be implemented to make development of the UI system easier.

- There will be no system to backpropagate the size of elements. If something doesn't fit where it needs to go, it will have to either spill out of bounds or get cut off. It is up to the developer to ensure that there is enough space for elements or make special cases when elements can't fit.
- There will be no universal method to get the size of an element before it gets rendered (elements will not neccessarily fit the cursor). Dear ImGui doesn't do this so why should ours? (one exception is text but in that case it is actually important)
- Nested scroll regions will not be allowed. This vastly simplifies things as there's no need to keep track of arbitrarily-deep, nested scroll regions.
- Elements do not need to behave like primitive elements when calling them and shouldn't be used as sub elements. Some duplicated behavior between elements is okay.

## Assumptions
Notable assumptions that the UI makes without enforcing them with error checking

- Scroll regions expect that all cursor data structures have returned to their original states from when scroll.start was called when scroll.finish is called. Not honoring this assumption is undefined behavior.
- Keyboard navigation cell and mouse sensor IDs need to remain assigned to the same elements between frames for keyboard and mouse interaction to function. (This may be a problem when the layout of a page suddenly changes, but the error will only last one frame.)
  - A good practice is to make elements always use the same amount of cell and sensor IDs even if they don't actually need them all. 

## Requirements

1. Minimize the use of cyclic dependencies.
   1. Requires should all be at the top of the file.
   2. Don't use requires inside functions unless it really makes sense to do so.
2. A draw queue that can be built out-of-order.
   1. Out-of-order building is achived with reservations
      1. Draw queue slots can be reserved and filled in later.
      2. Multiple reservations can be made at a time which can be filled in-order.
      3. Reservations take on the location of the placement: **\[when the reservation was taken\]** / when the reservation was made.
3. Recording keyboard and mouse navigation should not be put in state tables.
   1. This creates too many state tables
   2. The same functions to get mouse/keyboard navigation outputs should be used everywhere.
      1. These functions will only be accurate to the latest created placement/cell, respectively.
4. Mouse navigation is done at the end of the frame.
   1. Same as keyboard navigation.
5. A cursor which can be used to align and place elements.
   1. Support elements that don't fit the cursor.
   2. Cursor can be set to auto-reshape which will reshape itself to exactly surround an element that doesn't fit the cursor. 
   3. Support translating elements (no rotating).
   4. Cursor shall be agnostic to any external factors such as UI scale. 
6. Elements can be masked which cuts off drawing and mouse interaction.
   1. Masking should work even if the cursor is translated.

7. Checking for clicking and keyboard should work for entire elements, even after they're created. For example, this should work as you'd expect:
   ```lua
   button("a button")
   if m_nav.get_clicked() or kb_nav.get_action() then
      print("button clicked")
   end
   ``` 
   1. For more complex elements with multiple interactable regions, it should behave as if the entire element is one whole button.
8. Mouse dragging needs some way to know which specific element it is dragging. It can't just be what's under the mouse.
   1. Still not sure how to go about this yet. (With keyboard navigation, this is easy since every element gets it's own cell id.)
