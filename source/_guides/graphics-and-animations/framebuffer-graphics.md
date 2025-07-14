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

title: Framebuffer Graphics
description: |
  How to perform advanced drawing using direct framebuffer access.
guide_group: graphics-and-animations
order: 2
related_docs:
  - Graphics Context
  - GBitmap
  - GBitmapDataRowInfo
---

In the context of a Pebble app, the framebuffer is the data region used to store
the contents of the what is shown on the display. Using the ``Graphics Context``
API allows developers to draw primitive shapes and text, but at a slower speed
and with a restricted set of drawing patterns. Getting direct access to the
framebuffer allows arbitrary transforms, special effects, and other
modifications to be applied to the display contents, and allows drawing at a
much greater speed than standard SDK APIs.


## Accessing the Framebuffer

Access to the framebuffer can only be obtained during a ``LayerUpdateProc``,
when redrawing is taking place. When the time comes to update the associated
``Layer``, the framebuffer can be obtained as a ``GBitmap``:

```c
static void layer_update_proc(Layer *layer, GContext *ctx) {
  // Get the framebuffer
  GBitmap *fb = graphics_capture_frame_buffer(ctx);

  // Manipulate the image data...

  // Finally, release the framebuffer
  graphics_release_frame_buffer(ctx, fb);
}
```

> Note: Once obtained, the framebuffer **must** be released back to the app so
> that it may continue drawing.

The format of the data returned will vary by platform, as will the
representation of a single pixel, shown in the table below.

| Platform | Framebuffer Bitmap Format | Pixel Format |
|:--------:|---------------------------|--------------|
| Aplite | ``GBitmapFormat1Bit`` | One bit (black or white) |
| Basalt | ``GBitmapFormat8Bit`` | One byte (two bits per color) |
| Chalk | ``GBitmapFormat8BitCircular`` | One byte (two bits per color) |


## Modifying the Framebuffer Data

Once the framebuffer has been captured, the underlying data can be manipulated
on a row-by-row or even pixel-by-pixel basis. This data region can be obtained
using ``gbitmap_get_data()``, but the recommended approach is to make use of
``gbitmap_get_data_row_info()`` objects to cater for platforms (such as Chalk),
where not every row is of the same width. The ``GBitmapDataRowInfo`` object
helps with this by providing a `min_x` and `max_x` value for each `y` used to
build it.

To iterate over all rows and columns, safely avoiding those with irregular start
and end indices, use two nested loops as shown below. The implementation of
`set_pixel_color()` is shown in 
[*Getting and Setting Pixels*](#getting-and-setting-pixels):

> Note: it is only necessary to call ``gbitmap_get_data_row_info()`` once per
> row. Calling it more often (such as for every pixel) will incur a sigificant
> speed penalty.

```c
GRect bounds = layer_get_bounds(layer);

// Iterate over all rows
for(int y = 0; y < bounds.size.h; y++) {
  // Get this row's range and data
  GBitmapDataRowInfo info = gbitmap_get_data_row_info(fb, y);

  // Iterate over all visible columns
  for(int x = info.min_x; x <= info.max_x; x++) {
    // Manipulate the pixel at x,y...
    const GColor random_color = (GColor){ .argb = rand() % 255 };

    // ...to be a random color
    set_pixel_color(info, GPoint(x, y), random_color);
  }
}
```


## Getting and Setting Pixels

To modify a pixel's value, simply set a new value at the appropriate position in
the `data` field of that row's ``GBitmapDataRowInfo`` object. This will modify
the underlying data, and update the display once the frame buffer is released.

This process will be different depending on the ``GBitmapFormat`` of the
captured framebuffer. On a color platform, each pixel is stored as a single
byte. However, on black and white platforms this will be one bit per byte. Using
``memset()`` to read or modify the correct pixel on a black and white display
requires a bit more logic, shown below:

```c
static GColor get_pixel_color(GBitmapDataRowInfo info, GPoint point) {
#if defined(PBL_COLOR)
  // Read the single byte color pixel
  return (GColor){ .argb = info.data[point.x] };
#elif defined(PBL_BW)
  // Read the single bit of the correct byte
  uint8_t byte = point.x / 8;
  uint8_t bit = point.x % 8; 
  return byte_get_bit(&info.data[byte], bit) ? GColorWhite : GColorBlack;
#endif
}
```

Setting a pixel value is achieved in much the same way, with different logic
depending on the format of the framebuffer on each platform:

```c
static void set_pixel_color(GBitmapDataRowInfo info, GPoint point, 
                                                                GColor color) {
#if defined(PBL_COLOR)
  // Write the pixel's byte color
  memset(&info.data[point.x], color.argb, 1);
#elif defined(PBL_BW)
  // Find the correct byte, then set the appropriate bit
  uint8_t byte = point.x / 8;
  uint8_t bit = point.x % 8; 
  byte_set_bit(&info.data[byte], bit, gcolor_equal(color, GColorWhite) ? 1 : 0);
#endif
}
```

The `byte_get_bit()` and `byte_set_bit()` implementations are shown here for
convenience:

```c
static bool byte_get_bit(uint8_t *byte, uint8_t bit) {
  return ((*byte) >> bit) & 1;
}

static void byte_set_bit(uint8_t *byte, uint8_t bit, uint8_t value) {
  *byte ^= (-value ^ *byte) & (1 << bit);
}
```


## Learn More

To see an example of what can be achieved with direct access to the framebuffer
and learn more about the underlying principles, watch the 
[talk given at the 2014 Developer Retreat](https://www.youtube.com/watch?v=lYoHh19RNy4).

[EMBED](//www.youtube.com/watch?v=lYoHh19RNy4)
