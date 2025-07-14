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

layout: tutorials/tutorial
tutorial: watchface
tutorial_part: 4

title: Adding a Battery Bar
description: |
  How to add a battery level meter to your watchface.
permalink: /tutorials/watchface-tutorial/part4/
generate_toc: true
---

Another popular feature added to a lot of watchfaces is a battery meter,
enabling users to see the state of their Pebble's battery charge level at a
glance. This is typically implemented as the classic 'battery icon' that fills
up according to the current charge level, but some watchfaces favor the more
minimal approach, which will be implemented here.

This section continues from
[*Part 3*](/tutorials/watchface-tutorial/part3/), so be sure to re-use
your code or start with that finished project.

The state of the battery is obtained using the ``BatteryStateService``. This
service offers two modes of usage - 'peeking' at the current level, or
subscribing to events that take place when the battery state changes. The latter
approach will be adopted here. The battery level percentage will be stored in an
integer at the top of the file:

```c
static int s_battery_level;
```

As with all the Event Services, to receive an event when new battery information
is available, a callback must be registered. Create this callback using the
signature of ``BatteryStateHandler``, and use the provided
``BatteryChargeState`` parameter to store the current charge percentage:

```c
static void battery_callback(BatteryChargeState state) {
  // Record the new battery level
  s_battery_level = state.charge_percent;
}
```

To enable this function to be called when the battery level changes, subscribe
to updates in `init()`:

```c
// Register for battery level updates
battery_state_service_subscribe(battery_callback);
```

With the subscription in place, the UI can be created. This will take the form
of a ``Layer`` with a ``LayerUpdateProc`` that uses the battery level to draw a
thin, minimalist white meter along the top of the time display.

Create the ``LayerUpdateProc`` that will be used to draw the battery meter:

```c
static void battery_update_proc(Layer *layer, GContext *ctx) {

}
```

Declare this new ``Layer`` at the top of the file:

```c
static Layer *s_battery_layer;
```

Allocate the ``Layer`` in `main_window_load()`, assign it the ``LayerUpdateProc`` that will draw it, and
add it as a child of the main ``Window`` to make it visible:

```c
// Create battery meter Layer
s_battery_layer = layer_create(GRect(14, 54, 115, 2));
layer_set_update_proc(s_battery_layer, battery_update_proc);

// Add to Window
layer_add_child(window_get_root_layer(window), s_battery_layer);
```

To ensure the battery meter is updated every time the charge level changes, mark
it 'dirty' (to ask the system to re-render it at the next opportunity) within
`battery_callback()`:

```c
// Update meter
layer_mark_dirty(s_battery_layer);
```

The final piece of the puzzle is the actual drawing of the battery meter, which
takes place within the ``LayerUpdateProc``. The background of the meter is drawn
to 'paint over' the background image, before the width of the meter's 'bar' is
calculated using the current value as a percentage of the bar's total width
(114px).

The finished version of the update procedure is shown below:

```c
static void battery_update_proc(Layer *layer, GContext *ctx) {
  GRect bounds = layer_get_bounds(layer);

  // Find the width of the bar (total width = 114px)
  int width = (s_battery_level * 114) / 100;

  // Draw the background
  graphics_context_set_fill_color(ctx, GColorBlack);
  graphics_fill_rect(ctx, bounds, 0, GCornerNone);

  // Draw the bar
  graphics_context_set_fill_color(ctx, GColorWhite);
  graphics_fill_rect(ctx, GRect(0, 0, width, bounds.size.h), 0, GCornerNone);
}
```

Lastly, as with the ``TickTimerService``, the ``BatteryStateHandler`` can be
called manually in `init()` to display an inital value:

```c
// Ensure battery level is displayed from the start
battery_callback(battery_state_service_peek());
```

Don't forget to free the memory used by the new battery meter:

```c
layer_destroy(s_battery_layer);
```

With this new feature in place, the watchface will now display the watch's
battery charge level in a minimalist fashion that integrates well with the
existing design style.

![battery-level >{pebble-screenshot,pebble-screenshot--steel-black}](/images/tutorials/intermediate/battery-level.png)


## What's Next?

In the next, and final, section of this tutorial, we'll use the Connection Service
to notify the user when their Pebble smartwatch disconnects from their phone.

[Go to Part 5 &rarr; >{wide,bg-dark-red,fg-white}](/tutorials/watchface-tutorial/part5/)
