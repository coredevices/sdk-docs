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

title: Tips and Tricks - Transparent Images
author: chrislewis
tags:
   - Beautiful Code
---

Ever wondered how to draw transparent images in a Pebble app? This post will
walk you through the process.

In this post, we'll be using a sample image with a transparency component, shown
below:

<a href="{{ site.asset_path }}/images/blog/tips-transparency-globe.png" download>
<img src="{{ site.asset_path }}/images/blog/tips-transparency-globe.png">
</a>



When adding your project resource, ensure you set its ‘type’ correctly. On
CloudPebble, this is done when uploading the resource and choosing the 'PNG'
type. In the SDK, this is done with the `png` `type` in the project's
`appinfo.json`.

```js
"media": [
  {
    "type": "png",
    "name": "GLOBE",
    "file": "globe.png"
  }
]
```

This will create a resource ID to use in code:

```text
RESOURCE_ID_GLOBE
```

Simply create a ``GBitmap`` with this resource and draw the image with
``GCompOpSet`` as the compositing mode:

```c
static GBitmap *s_bitmap;
static Layer *s_canvas_layer;
```

```c
static void window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);

  // Create GBitmap
  s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_GLOBE);

  // Create canvas Layer
  s_canvas_layer = layer_create(layer_get_bounds(window_layer));
  layer_set_update_proc(s_canvas_layer, layer_update_proc);
  layer_add_child(window_layer, s_canvas_layer);
}
```

```c
static void layer_update_proc(Layer *layer, GContext *ctx) {
  // Draw the image with the correct compositing mode
  graphics_context_set_compositing_mode(ctx, GCompOpSet);
  graphics_draw_bitmap_in_rect(ctx, s_bitmap, gbitmap_get_bounds(s_bitmap));
}
```

When drawing on a ``TextLayer`` underneath `s_canvas_layer`, the result looks
like this:

![result-aplite >{pebble-screenshot,pebble-screenshot--steel-black}](/images/blog/tips-result-aplite.png)


See a full demo of this technique on the
[pebble-examples GitHub repo]({{site.links.examples_org}}/feature-image-transparent).

Job done! Any transparent pixels in the original image will be drawn as clear,
leaving the color beneath unaffected.

Read the [Image Resources](/guides/app-resources/) guide to learn more
about transparent PNGs.


## Conclusion

So there you have it. Using these examples you can easily implement transparency
on all Pebble platforms. To learn more, read the ``GCompOp`` documentation or
the
[`pebble-examples/feature-image-transparent`]({{site.links.examples_org}}/feature-image-transparent)
SDK example.
