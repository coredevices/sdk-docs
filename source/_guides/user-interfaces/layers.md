---
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

title: Layers
description: |
  How to use standard Layer components to build an app's UI.
guide_group: user-interfaces
order: 3
related_docs:
  - Layer
  - LayerUpdateProc
  - Window
  - TextLayer
  - BitmapLayer
  - MenuLayer
  - ScrollLayer
---

The ``Layer`` and associated subclasses (such as ``TextLayer`` and
``BitmapLayer``) form the foundation of the UI for every Pebble watchapp or
watchface, and are added to a ``Window`` to construct the UI's design. Each
``Layer`` type contains at least three basic elements:

* Frame - contains the position and dimensions of the ``Layer``, relative to the
  parent object.

* Bounds - contains the drawable bounding box within the frame. This allows only
  a portion of the layer to be visible, and is relative to the ``Layer`` frame.

* Update procedure - the function that performs the drawing whenever the
  ``Layer`` is rendered. The subclasses implement a convenience update procedure
  with additional data to achieve their specialization.


## Layer Heirachy

Every app must consist of at least one ``Window`` in order to successfully
launch. Mutiple ``Layer`` objects are added as children of the ``Window``, which
itself contains a ``Layer`` known as the 'root layer'. When the ``Window`` is
rendered, each child ``Layer`` is rendered in the order in which they were
added. For example:

```c
static Window *s_main_window;

static BitmapLayer *s_background_layer;
static TextLayer *s_time_layer;
```

```c
// Get the Window's root layer
Layer *root_layer = window_get_root_layer(s_main_window);

/* set up BitmapLayer and TextLayer */

// Add the background layer first, so that it is drawn behind the time
layer_add_child(root_layer, bitmap_layer_get_layer(s_background_layer));

// Add the time layer second
layer_add_child(root_layer, text_layer_get_layer(s_time_layer));
```

Once added to a ``Window``, the ordering of each ``Layer`` cannot be modified,
but one can be placed at the front by removing and re-adding it to the heirachy:

```c
// Bring a layer to the front
layer_remove_from_parent(s_some_layer);
layer_add_child(root_layer, s_some_layer);
```


## Update Procedures

For creating custom drawing implementations, the basic ``Layer`` update
procedure can be reassigned to one created by a developer. This takes the form
of a ``LayerUpdateProc``, and provides a [`GContext`](``Graphics Context``)
object which can be used for drawing primitive shapes, paths, text, and images.

> Note: See {% guide_link graphics-and-animations %} for more information on
> drawing with the graphics context.

```c
static void layer_update_proc(Layer *layer, GContext *ctx) {
  // Custom drawing happens here
}
```

This function must then be assigned to the ``Layer`` that will be drawn with it:

```c
// Set this Layer's update procedure
layer_set_update_proc(s_some_layer, layer_update_proc);
```

The update procedure will be called every time the ``Layer`` must be redrawn.
This is typically when any other ``Layer`` requests a redraw, the ``Window`` is
shown/hidden, the heirarchy changes, or a modal (such as a notification) appears.
The ``Layer`` can also be manually marked as 'dirty', and will be redrawn at the
next opportunity (usually immediately):

```c
// Request a redraw
layer_mark_dirty(s_some_layer);
```


## Layer Subclasses

For convenience, there are multiple subclasses of ``Layer`` included in the
Pebble SDK to allow developers to easily construct their app's UI. Each should
be created when the ``Window`` is loading (using the `.load` ``WindowHandler``)
and destroyed when it is unloading (using `.the unload` ``WindowHandler``).

These are briefly outlined below, alongside a simple usage example split into
three code snippets - the element declarations, the setup procedure, and the
teardown procedure.


### TextLayer

The ``TextLayer`` is the most commonly used subclass of ``Layer``, and allows
apps to render text using any available font, with built-in behavior to handle
text color, line wrapping, alignment, etc.

```c
static TextLayer *s_text_layer;
```

```c
// Create a TextLayer
s_text_layer = text_layer_create(bounds);

// Set some properties
text_layer_set_text_color(s_text_layer, GColorWhite);
text_layer_set_background_color(s_text_layer, GColorBlack);
text_layer_set_overflow_mode(s_text_layer, GTextOverflowModeWordWrap);
text_layer_set_alignment(s_text_layer, GTextAlignmentCenter);

// Set the text shown
text_layer_set_text(s_text_layer, "Hello, World!");

// Add to the Window
layer_add_child(root_layer, text_layer_get_layer(s_text_layer));
```

```c
// Destroy the TextLayer
text_layer_destroy(s_text_layer);
```


### BitmapLayer

The ``BitmapLayer`` provides an easy way to show images loaded into ``GBitmap``
objects from an image resource. Images shown using a ``BitmapLayer`` are
automatically centered within the bounds provided to ``bitmap_layer_create()``.
Read {% guide_link app-resources/images %} to learn more about using image
resources in apps.

> Note: PNG images with transparency should use `bitmap` resource type, and use
> the ``GCompOpSet`` compositing mode when being displayed, as shown below.

```c
static BitmapLayer *s_bitmap_layer;
static GBitmap *s_bitmap;
```

```c
// Load the image
s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);

// Create a BitmapLayer
s_bitmap_layer = bitmap_layer_create(bounds);

// Set the bitmap and compositing mode
bitmap_layer_set_bitmap(s_bitmap_layer, s_bitmap);
bitmap_layer_set_compositing_mode(s_bitmap_layer, GCompOpSet);

// Add to the Window
layer_add_child(root_layer, bitmap_layer_get_layer(s_bitmap_layer));
```

```c
// Destroy the BitmapLayer
bitmap_layer_destroy(s_bitmap_layer);
```


### StatusBarLayer

If a user needs to see the current time inside an app (instead of exiting to the
watchface), the ``StatusBarLayer`` component can be used to display this
information at the top of the ``Window``. Colors and separator display style can
be customized.

```c
static StatusBarLayer *s_status_bar;
```

```c
// Create the StatusBarLayer
s_status_bar = status_bar_layer_create();

// Set properties
status_bar_layer_set_colors(s_status_bar, GColorBlack, GColorBlueMoon);
status_bar_layer_set_separator_mode(s_status_bar, 
                                            StatusBarLayerSeparatorModeDotted);

// Add to Window
layer_add_child(root_layer, status_bar_layer_get_layer(s_status_bar));
```

```c
// Destroy the StatusBarLayer
status_bar_layer_destroy(s_status_bar);
```


### MenuLayer

The ``MenuLayer`` allows the user to scroll a list of options using the Up and
Down buttons, and select an option to trigger an action using the Select button.
It differs from the other ``Layer`` subclasses in that it makes use of a number
of ``MenuLayerCallbacks`` to allow the developer to fully control how it renders
and behaves. Some minimum example callbacks are shown below:

```c
static MenuLayer *s_menu_layer;
```

```c
static uint16_t get_num_rows_callback(MenuLayer *menu_layer, 
                                      uint16_t section_index, void *context) {
  const uint16_t num_rows = 5;
  return num_rows;
}

static void draw_row_callback(GContext *ctx, const Layer *cell_layer, 
                                        MenuIndex *cell_index, void *context) {
  static char s_buff[16];
  snprintf(s_buff, sizeof(s_buff), "Row %d", (int)cell_index->row);

  // Draw this row's index
  menu_cell_basic_draw(ctx, cell_layer, s_buff, NULL, NULL);
}

static int16_t get_cell_height_callback(struct MenuLayer *menu_layer, 
                                        MenuIndex *cell_index, void *context) {
  const int16_t cell_height = 44;
  return cell_height;
}

static void select_callback(struct MenuLayer *menu_layer, 
                                        MenuIndex *cell_index, void *context) {
  // Do something in response to the button press
  
}
```

```c
// Create the MenuLayer
s_menu_layer = menu_layer_create(bounds);

// Let it receive click events
menu_layer_set_click_config_onto_window(s_menu_layer, window);

// Set the callbacks for behavior and rendering
menu_layer_set_callbacks(s_menu_layer, NULL, (MenuLayerCallbacks) {
    .get_num_rows = get_num_rows_callback,
    .draw_row = draw_row_callback,
    .get_cell_height = get_cell_height_callback,
    .select_click = select_callback,
});

// Add to the Window
layer_add_child(root_layer, menu_layer_get_layer(s_menu_layer));
```

```c
// Destroy the MenuLayer
menu_layer_destroy(s_menu_layer);
```


### ScrollLayer

The ``ScrollLayer`` provides an easy way to use the Up and Down buttons to
scroll large content that does not all fit onto the screen at the same time. The
usage of this type differs from the others in that the ``Layer`` objects that
are scrolled are added as children of the ``ScrollLayer``, which is then in turn
added as a child of the ``Window``.

The ``ScrollLayer`` frame is the size of the 'viewport', while the content size
determines how far the user can scroll in each direction. The example below
shows a ``ScrollLayer`` scrolling some long text, the total size of which is
calculated with ``graphics_text_layout_get_content_size()`` and used as the
``ScrollLayer`` content size.

> Note: The scrolled ``TextLayer`` frame is relative to that of its parent, the
> ``ScrollLayer``.

```c
static TextLayer *s_text_layer;
static ScrollLayer *s_scroll_layer;
```

```c
GFont font = fonts_get_system_font(FONT_KEY_GOTHIC_28_BOLD);

// Find the bounds of the scrolling text
GRect shrinking_rect = GRect(0, 0, bounds.size.w, 2000);
char *text = "Example text that is really really really really really \
                              really really really really really really long";
GSize text_size = graphics_text_layout_get_content_size(text, font, 
                shrinking_rect, GTextOverflowModeWordWrap, GTextAlignmentLeft);
GRect text_bounds = bounds;
text_bounds.size.h = text_size.h;

// Create the TextLayer
s_text_layer = text_layer_create(text_bounds);
text_layer_set_overflow_mode(s_text_layer, GTextOverflowModeWordWrap);
text_layer_set_font(s_text_layer, font);
text_layer_set_text(s_text_layer, text);

// Create the ScrollLayer
s_scroll_layer = scroll_layer_create(bounds);

// Set the scrolling content size
scroll_layer_set_content_size(s_scroll_layer, text_size);

// Let the ScrollLayer receive click events
scroll_layer_set_click_config_onto_window(s_scroll_layer, window);

// Add the TextLayer as a child of the ScrollLayer
scroll_layer_add_child(s_scroll_layer, text_layer_get_layer(s_text_layer));

// Add the ScrollLayer as a child of the Window
layer_add_child(root_layer, scroll_layer_get_layer(s_scroll_layer));
```

```c
// Destroy the ScrollLayer and TextLayer
scroll_layer_destroy(s_scroll_layer);
text_layer_destroy(s_text_layer);
```


### ActionBarLayer

The ``ActionBarLayer`` allows apps to use the familiar black right-hand bar,
featuring icons denoting the action that will occur when each button on the
right hand side is pressed. For example, 'previous track', 'more actions', and
'next track' in the built-in Music app. 

For three or fewer actions, the ``ActionBarLayer`` can be more appropriate than
a ``MenuLayer`` for presenting the user with a list of actionable options. Each
action's icon must also be loaded into a ``GBitmap`` object from app resources.
The example below demonstrates show to set up an ``ActionBarLayer`` showing an
up, down, and checkmark icon for each of the buttons.

```c
static ActionBarLayer *s_action_bar;
static GBitmap *s_up_bitmap, *s_down_bitmap, *s_check_bitmap;
```

```c
// Load icon bitmaps
s_up_bitmap = gbitmap_create_with_resource(RESOURCE_ID_UP_ICON);
s_down_bitmap = gbitmap_create_with_resource(RESOURCE_ID_DOWN_ICON);
s_check_bitmap = gbitmap_create_with_resource(RESOURCE_ID_CHECK_ICON);

// Create ActionBarLayer
s_action_bar = action_bar_layer_create();
action_bar_layer_set_click_config_provider(s_action_bar, click_config_provider);

// Set the icons
action_bar_layer_set_icon(s_action_bar, BUTTON_ID_UP, s_up_bitmap);
action_bar_layer_set_icon(s_action_bar, BUTTON_ID_DOWN, s_down_bitmap);
action_bar_layer_set_icon(s_action_bar, BUTTON_ID_SELECT, s_check_bitmap);

// Add to Window
action_bar_layer_add_to_window(s_action_bar, window);
```

```c
// Destroy the ActionBarLayer
action_bar_layer_destroy(s_action_bar);

// Destroy the icon GBitmaps
gbitmap_destroy(s_up_bitmap);
gbitmap_destroy(s_down_bitmap);
gbitmap_destroy(s_check_bitmap);
```
