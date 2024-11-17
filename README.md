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
