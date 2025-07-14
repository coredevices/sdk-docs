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

title: Round App UI
description: |
  Details on how to use the Pebble SDK to create layouts specifically for round
  displays.
guide_group: user-interfaces
order: 4
related_docs:
  - Graphics
  - LayerUpdateProc
related_examples:
  - title: Time Dots
    url: https://github.com/pebble-examples/time-dots/
  - title: Text Flow Techniques
    url: https://github.com/pebble-examples/text-flow-techniques
platforms:
  - chalk
---

> This guide is about creating round apps in code. For advice on designing a
> round app, read {% guide_link design-and-interaction/in-the-round %}.

With the addition of Pebble Time Round (the Chalk platform) to the Pebble
family, developers face a new challenge - circular apps! With this display
shape, traditional layouts will not display properly due to the obscuring of the
corners. Another potential issue is the increased display resolution. Any UI
elements that were not previously centered correctly (or drawn with hardcoded
coordinates) will also display incorrectly.

However, the Pebble SDK provides additions and functionality to help developers
cope with this way of thinking. In many cases, a round display can be an
aesthetic advantage. An example of this is the traditional circular dial
watchface, which has been emulated on Pebble many times, but also wastes corner
space. With a round display, these watchfaces can look better than ever.

![time-dots >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/time-dots.png)


## Detecting Display Shape

The first step for any app wishing to correctly support both display shapes is
to use the available compiler directives to conditionally create the UI. This
can be done as shown below:

```c
#if defined(PBL_RECT)
  printf("This code is run on a rectangular display!");

  /* Rectangular UI code */
#elif defined(PBL_ROUND)
  printf("This code is run on a round display!");

  /* Round UI code */
#endif
```

Another approach for single value selection is the ``PBL_IF_RECT_ELSE()`` and
``PBL_IF_ROUND_ELSE()`` macros, which accept two parameters for each of the
respective round and rectangular cases. For example, ``PBL_IF_RECT_ELSE()`` will
compile the first parameter on a rectangular display, and the second one
otherwise:

```c
// Conditionally print out the shape of the display
printf("This is a %s display!", PBL_IF_RECT_ELSE("rectangular", "round"));
```


## Circular Drawing

In addition to the older ``graphics_draw_circle()`` and
``graphics_fill_circle()`` functions, the Pebble SDK for the chalk platform
contains additional functions to help draw shapes better suited for a round
display. These include:

* ``graphics_draw_arc()`` - Draws a line arc clockwise between two angles within
  a given ``GRect`` area, where 0° is the top of the circle.

* ``graphics_fill_radial()`` - Fills a circle clockwise between two angles
  within a given ``GRect`` area, with adjustable inner inset radius allowing the
  creation of 'doughnut-esque' shapes.

* ``gpoint_from_polar()`` - Returns a ``GPoint`` object describing a point given
  by a specified angle within a centered ``GRect``.

In the Pebble SDK angles between `0` and `360` degrees are specified as values
scaled between `0` and ``TRIG_MAX_ANGLE`` to preserve accuracy and avoid
floating point math. These are most commonly used when dealing with drawing
circles. To help with this conversion, developers can use the
``DEG_TO_TRIGANGLE()`` macro.

An example function to draw the letter 'C' in a yellow color is shown below for
use in a ``LayerUpdateProc``.

```c
static void draw_letter_c(GRect bounds, GContext *ctx) {
  GRect frame = grect_inset(bounds, GEdgeInsets(30));

  graphics_context_set_fill_color(ctx, GColorYellow);
  graphics_fill_radial(ctx, frame, GOvalScaleModeFitCircle, 30,
                                  DEG_TO_TRIGANGLE(-225), DEG_TO_TRIGANGLE(45));
}
```

This produces the expected result, drawn with a smooth antialiased filled circle
arc between the specified angles.

![letter-c >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/letter-c.png)


## Adaptive Layouts

With not only a difference in display shape, but also in resolution, it is very
important that an app's layout not be created using hardcoded coordinates.
Consider the examples below, designed to create a child ``Layer`` to fill the
size of the parent layer.

```c
// Bad - only works on Aplite and Basalt rectangular displays
Layer *layer = layer_create(GRect(0, 0, 144, 168));

// Better - uses the native display size
GRect bounds = layer_get_bounds(parent_layer);
Layer *layer = layer_create(bounds);
```

Using this style, the child layer will always fill the parent layer, regardless
of its actual dimensions.

In a similar vein, when working with the Pebble Time Round display it can be
important that the layout is centered correctly. A set of layout values that are
in the center of the classic 144 x 168 pixel display will not be centered when
displayed on a 180 x 180 display. The undesirable effect of this can be seen in
the example shown below:

![cut-corners >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/cut-corners.png)

By using the technique described above, the layout's ``GRect`` objects can
specify their `origin` and `size` as a function of the dimensions of the layer
they are drawn into, solving this problem.

![centered >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/centered.png)


## Text Flow and Pagination

A chief concern when working with a circular display is the rendering of large
amounts of text. As demonstrated by an animation in
{% guide_link design-and-interaction/in-the-round#pagination %}, continuous
reflowing of text makes it much harder to read.

A solution to this problem is to render text while flowing within the
constraints of the shape of the display, and to scroll/animate it one page at a
time. There are three approaches to this available to developers, which are
detailed below. For full examples of each, see the
[`text-flow-techniques`](https://github.com/pebble-examples/text-flow-techniques)
example app.


### Using TextLayer

Additions to the ``TextLayer`` API allow text rendered within it to be
automatically flowed according to the curve of the display, and paged correctly
when the layer is moved or animated further. After a ``TextLayer`` is created in
the usual way, text flow can then be enabled:

```c
// Create TextLayer
TextLayer *s_text_layer = text_layer_create(bounds);

/* other properties set up */

// Add to parent Window
layer_add_child(window_layer, text_layer_get_layer(s_text_layer));

// Enable paging and text flow with an inset of 5 pixels
text_layer_enable_screen_text_flow_and_paging(s_text_layer, 5);
```

> Note: The ``text_layer_enable_screen_text_flow_and_paging()`` function must be
> called **after** the ``TextLayer`` is added to the view heirachy (i.e.: after
> using ``layer_add_child()``), or else it will have no effect.

An example of two ``TextLayer`` elements flowing their text within the
constraints of the display shape is shown below:

![text-flow >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/pebble-apps/display-animations/text-flow.png)


### Using ScrollLayer

The ``ScrollLayer`` UI component also contains round-friendly functionality,
allowing it to scroll its child ``Layer`` elements in pages of the same height
as its frame (usually the size of the parent ``Window``). This allows consuming
long content to be a more consistent experience, whether it is text, images, or
some other kind of information.

```c
// Enable ScrollLayer paging
scroll_layer_set_paging(s_scroll_layer, true);
```

When combined with a ``TextLayer`` as the main child layer, it becomes easy to
display long pieces of textual content on a round display. The ``TextLayer`` can
be set up to handle the reflowing of text to follow the display shape, and the
``ScrollLayer`` handles the paginated scrolling.

```c
// Add the TextLayer and ScrollLayer to the view heirachy
scroll_layer_add_child(s_scroll_layer, text_layer_get_layer(s_text_layer));
layer_add_child(window_layer, scroll_layer_get_layer(s_scroll_layer));

// Set the ScrollLayer's content size to the total size of the text
scroll_layer_set_content_size(s_scroll_layer,
                              text_layer_get_content_size(s_text_layer));

// Enable TextLayer text flow and paging
const int inset_size = 2;
text_layer_enable_screen_text_flow_and_paging(s_text_layer, inset_size);

// Enable ScrollLayer paging
scroll_layer_set_paging(s_scroll_layer, true);
```


### Manual Text Drawing

The drawing of text into a [`Graphics Context`](``Drawing Text``) can also be
performed with awareness of text flow and paging preferences. This can be used
to emulate the behavior of the two previous approaches, but with more
flexibility. This approach involves the use of the ``GTextAttributes`` object,
which is given to the Graphics API to allow it to flow text and paginate when
being animated.

When initializing the ``Window`` that will do the drawing:

```c
// Create the attributes object used for text rendering
GTextAttributes *s_attributes = graphics_text_attributes_create();

// Enable text flow with an inset of 5 pixels
graphics_text_attributes_enable_screen_text_flow(s_attributes, 5);

// Enable pagination with a fixed reference point and bounds, used for animating
graphics_text_attributes_enable_paging(s_attributes, bounds.origin, bounds);
```

When drawing some text in a ``LayerUpdateProc``:

```c
static void update_proc(Layer *layer, GContext *ctx) {
  GRect bounds = layer_get_bounds(layer);

  // Calculate size of the text to be drawn with current attribute settings
  GSize text_size = graphics_text_layout_get_content_size_with_attributes(
    s_sample_text, fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD), bounds,
    GTextOverflowModeWordWrap, GTextAlignmentCenter, s_attributes
  );

  // Draw the text in this box with the current attribute settings
  graphics_context_set_text_color(ctx, GColorBlack);
  graphics_draw_text(ctx, s_sample_text, fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD),
    GRect(bounds.origin.x, bounds.origin.y, text_size.w, text_size.h),
    GTextOverflowModeWordWrap, GTextAlignmentCenter, s_attributes
  );
}
```

Once this setup is complete, the text will display correctly when moved or
scrolled via a ``PropertyAnimation``, such as one that moves the ``Layer`` that
draws the text upwards, and at the same time extending its height to display
subsequent pages. An example animation is shown below:

```c
GRect window_bounds = layer_get_bounds(window_get_root_layer(s_main_window));
const int duration_ms = 1000;

// Animate the Layer upwards, lengthening it to allow the next page to be drawn
GRect start = layer_get_frame(s_layer);
GRect finish = GRect(start.origin.x, start.origin.y - window_bounds.size.h,
                     start.size.w, start.size.h * 2);

// Create and scedule the PropertyAnimation
PropertyAnimation *prop_anim = property_animation_create_layer_frame(
                                                      s_layer, &start, &finish);
Animation *animation = property_animation_get_animation(prop_anim);
animation_set_duration(animation, duration_ms);
animation_schedule(animation);
```


## Working With a Circular Framebuffer

The traditional rectangular Pebble app framebuffer is a single continuous memory
segment that developers could access with ``gbitmap_get_data()``. With a round
display, Pebble saves memory by clipping sections of each line of difference
between the display area and the rectangle it occupies. The resulting masking
pattern looks like this:

![mask](/images/guides/pebble-apps/display-animations/mask.png)

> Download this mask by saving the PNG image above, or get it as a
> [Photoshop PSD layer](/assets/images/guides/pebble-apps/display-animations/round-mask-layer.psd).

This has an important implication - the memory segment of the framebuffer can no
longer be accessed using classic `y * row_width + x` formulae. Instead,
developers should use the ``gbitmap_get_data_row_info()`` API. When used with a
given y coordinate, this will return a ``GBitmapDataRowInfo`` object containing
a pointer to the row's data, as well as values for the minumum and maximum
visible values of x coordinate on that row. For example:

```c
static void round_update_proc(Layer *layer, GContext *ctx) {
  // Get framebuffer
  GBitmap *fb = graphics_capture_frame_buffer(ctx);
  GRect bounds = layer_get_bounds(layer);

  // Write a value to all visible pixels
  for(int y = 0; y < bounds.size.h; y++) {
    // Get the min and max x values for this row
    GBitmapDataRowInfo info = gbitmap_get_data_row_info(fb, y);

    // Iterate over visible pixels in that row
    for(int x = info.min_x; x < info.max_x; x++) {
      // Set the pixel to black
      memset(&info.data[x], GColorBlack.argb, 1);
    }
  }

  // Release framebuffer
  graphics_release_frame_buffer(ctx, fb);
}
```


## Displaying More Content

When more content is available than fits on the screen at any one time, the user
should be made aware using visual clues. The best way to do this is to use the
``ContentIndicator`` UI component.

![content-indicator >{pebble-screenshot,pebble-screenshot--time-round-silver-20}](/images/guides/design-and-interaction/content-indicator.png)

A ``ContentIndicator`` can be obtained in two ways. It can be created from
scratch with ``content_indicator_create()`` and manually managed to determine
when the arrows should be shown, or a built-in instance can be obtained from a
``ScrollLayer``, as shown below:

```c
// Get the ContentIndicator from the ScrollLayer
s_indicator = scroll_layer_get_content_indicator(s_scroll_layer);
```

In order to draw the arrows indicating more information in each direction, the
``ContentIndicator`` must be supplied with two new ``Layer`` elements that will
be used to do the drawing. These should also be added as children to the main
``Window`` root ``Layer`` such that they are visible on top of all other
``Layer`` elements:

```c
static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  /* ... */

  // Create two Layers to draw the arrows
  s_indicator_up_layer = layer_create(
                          GRect(0, 0, bounds.size.w, STATUS_BAR_LAYER_HEIGHT));
  s_indicator_down_layer = layer_create(
                          GRect(0, bounds.size.h - STATUS_BAR_LAYER_HEIGHT,
                                bounds.size.w, STATUS_BAR_LAYER_HEIGHT));

  /* ... */

  // Add these Layers as children after all other components to appear below
  layer_add_child(window_layer, s_indicator_up_layer);
  layer_add_child(window_layer, s_indicator_down_layer);
}
```

Once the indicator ``Layer`` elements have been created, each of the up and down
directions for conventional vertical scrolling must be configured with data to
control its behavior. Aspects such as the color of the arrows and background,
whether or not the arrows time out after being brought into view, and the
alignment of the drawn arrow within the ``Layer`` itself are configured with a
`const` ``ContentIndicatorConfig`` object when each direction is being
configured:

```c
// Configure the properties of each indicator
const ContentIndicatorConfig up_config = (ContentIndicatorConfig) {
  .layer = s_indicator_up_layer,
  .times_out = false,
  .alignment = GAlignCenter,
  .colors = {
    .foreground = GColorBlack,
    .background = GColorWhite
  }
};
content_indicator_configure_direction(s_indicator, ContentIndicatorDirectionUp,
                                      &up_config);

const ContentIndicatorConfig down_config = (ContentIndicatorConfig) {
  .layer = s_indicator_down_layer,
  .times_out = false,
  .alignment = GAlignCenter,
  .colors = {
    .foreground = GColorBlack,
    .background = GColorWhite
  }
};
content_indicator_configure_direction(s_indicator, ContentIndicatorDirectionDown,
                                      &down_config);
```

Unless the ``ContentIndicator`` has been retrieved from another ``Layer`` type
that includes an instance, it should be destroyed along with its parent
``Window``:

```c
// Destroy a manually created ContentIndicator
content_indicator_destroy(s_indicator);
```

For layouts that use the ``StatusBarLayer``, the ``ContentIndicatorDirectionUp``
`.layer` in the ``ContentIndicatorConfig`` object can be given the status bar's
``Layer`` with ``status_bar_layer_get_layer()``, and the drawing routines for
each will be managed automatically.
