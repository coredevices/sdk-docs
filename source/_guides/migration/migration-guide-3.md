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

title: SDK 3.x Migration Guide
description: Migrating Pebble apps from SDK 2.x to SDK 3.x.
permalink: /guides/migration/migration-guide-3/
generate_toc: true
guide_group: migration
order: 2
---

This guide provides a detailed list of the changes to existing APIs in Pebble
SDK 3.x. To migrate an older app's code successfully from Pebble SDK 2.x to
Pebble SDK 3.x, consider the information outlined here and make the necessary
changes if the app uses a changed API.

The number of breaking changes in SDK 3.x for existing apps has been minimized
as much as possible. This means that:

* Apps built with SDK 2.x **will continue to run on firmware 3.x without any
  recompilation needed**.

* Apps built with SDK 3.x will generate a `.pbw` file that will run on firmware
  3.x.


## Backwards Compatibility

Developers can easily modify an existing app (or create a new one) to be
compilable for both Pebble/Pebble Steel as well as Pebble Time, Pebble Time
Steel, and Pebble Time Round by using `#ifdef` and various defines that are made
available by the SDK at build time. For example, to check that the app will run
on hardware supporting color:

```c
#ifdef PBL_COLOR
  window_set_background_color(s_main_window, GColorDukeBlue);
#else
  window_set_background_color(s_main_window, GColorBlack);
#endif
```

When the app is compiled, it will be built once for each platform with
`PBL_COLOR` defined as is appropriate. By catering for all cases, apps will run
and look good on both platforms with minimal effort. This avoids the need to
maintain two Pebble projects for one app.

In addition, as of Pebble SDK 3.6 there are macros that can be used to
selectively include code in single statements. This is an alternative to the
approach shown above using `#ifdef`:

```c
window_set_background_color(s_main_window,
                            PBL_IF_COLOR_ELSE(GColorDukeBlue, GColorBlack));
```

See 
{% guide_link best-practices/building-for-every-pebble %}
to learn more about these macros, as well as see a complete list.


## PebbleKit Considerations

Apps that use PebbleKit Android will need to be re-compiled in Android Studio
(or similar) with the PebbleKit Android **3.x** (see 
{% guide_link communication/using-pebblekit-android %})
library in order to be compatible with the Pebble Time mobile application.
No code changes are required, however.

PebbleKit iOS developers remain unaffected and their apps will continue to run
with the new Pebble mobile application. However, iOS companion apps will need to
be recompiled with PebbleKit iOS **3.x** (see 
{% guide_link migration/pebblekit-ios-3 "PebbleKit iOS 3.0 Migration Guide" %}) 
to work with Pebble Time Round.


## Changes to appinfo.json

There is a new field for tracking which version of the SDK the app is built for.
For example, when using 3.x SDK add this line to the project's `appinfo.json`.

```
"sdkVersion": "3"
```

Apps will specify which hardware platforms they support (and wish to be built
for) by declaring them in the `targetPlatforms` field of the project's
`appinfo.json` file.

```
"targetPlatforms": [
  "aplite",
  "basalt",
  "chalk"
]
```

For each platform listed here, the SDK will generate an appropriate binary and
resource pack that will be included in the `.pbw` file. This means that the app
is actually compiled and resources are optimized once for each platform. The
image below summarizes this build process:

![build process](/images/sdk/build-process-3.png)

> Note: If `targetPlatforms` is not specified in `appinfo.json` the app will be
> compiled for all platforms. 

Apps can also elect to not appear in the app menu on the watch (if is is only
pushing timeline pins, for example) by setting `hiddenApp`:

```
"watchapp": {
  "watchface": false,
  "hiddenApp": true
},
```


## Project Resource Processing

SDK 3.x enhances the options for adding image resources to a Pebble project,
including performing some pre-processing of images into compatible formats prior
to bundling. For more details on the available resource types, check out the 
{% guide_link app-resources %} section of the guides.


## Platform-specific Resources

**Different Resources per Platform**

It is possible to include different versions of resources on only one of the
platforms with a specific type of display. Do this by appending `~bw` or
`~color` to the name of the resource file and the SDK will prefer that file over
another with the same name, but lacking the suffix.

This means is it possible to can include a smaller black and white version of an
image by naming it `example-image~bw.png`, which will be included in the
appropriate build over another file named `example-image.png`. In a similar
manner, specify a resource for a color platform by appending `~color` to the
file name.

An example file structure is shown below.

```text
my-project/
  resources/
    images/
      example-image~bw.png
      example-image~color.png
  src/
    main.c
  appinfo.json
  wscript
```

This resource will appear in `appinfo.json` as shown below.

```
"resources": {
  "media": [
    {
      "type": "bitmap",
      "name": "EXAMPLE_IMAGE",
      "file": "images/example-image.png"
    }
  ]
}
```

Read {% guide_link app-resources/platform-specific %} for more information about
specifying resources per-platform.

**Single-platform Resources**

To only include a resource on a **specific** platform, add a `targetPlatforms`
field to the resource's entry in the `media` array in `appinfo.json`. For
example, the resource shown below will only be included for the Basalt build.

```
"resources": {
  "media": [
    {
      "type": "bitmap",
      "name": "BACKGROUND_IMAGE",
      "file": "images/background.png",
      "targetPlatforms": [
        "basalt"
      ]
    }
  ]
}
```


## Changes to wscript

To support compilation for multiple hardware platforms and capabilities, the
default `wscript` file included in every Pebble project has been updated.

If a project uses a customized `wscript` file and `pebble convert-project` is
run (which will fully replace the file with a new compatible version), the
`wscript` will be copied to `wscript.backup`.

View 
[this GitHub gist](https://gist.github.com/pebble-gists/72a1a7c85980816e7f9b)
to see a sample of what the new format looks like, and re-add any customizations
afterwards.


## Changes to Timezones

With SDK 2.x, all time-related SDK functions returned values in local time, with
no concept of timezones. With SDK 3.x, the watch is aware of the user's timezone
(specified in Settings), and will return values adjusted for this value.


## API Changes Quick Reference

### Compatibility Macros

Since SDK 3.0-dp2, `pebble.h` includes compatibility macros enabling developers
to use the new APIs to access fields of opaque structures and still be
compatible with both platforms. An example is shown below:

```c
static GBitmap *s_bitmap;
```

```c
// SDK 2.9
GRect bounds = s_bitmap->bounds;

// SDK 3.x
GRect bounds = gbitmap_get_bounds(s_bitmap);
```


### Comparing Colors

Instead of comparing two GColor values directly, use the new ``gcolor_equal``
function to check for identical colors.

```c
GColor a, b;

// SDK 2.x, bad
if (a == b) { }

// SDK 3.x, good
if (gcolor_equal(a, b)) { }
```

> Note: Two colors with an alpha transparency(`.a`) component equal to `0`
> (completely transparent) are considered as equal.


### Assigning Colors From Integers

Specify a color previously stored as an `int` and convert it to a
`GColor`:

```c
GColor a;

// SDK 2.x
a = (GColor)persist_read_int(key);

// SDK 3.x
a.argb = persist_read_int(key);

/* OR */

a = (GColor){.argb = persist_read_int(key)};
```


### Specifying Black and White

The internal representation of SDK 2.x colors such as ``GColorBlack`` and
``GColorWhite`` have changed, but they can still be used with the same name.


### PebbleKit JS Account Token

In SDK 3.0 the behavior of `Pebble.getAccountToken()` changes slightly. In
previous versions, the token returned on Android could differ from that returned
on iOS by dropping some zero characters. The table below shows the different
tokens received for a single user across platforms and versions:

| Platform | Token |
|:---------|-------|
| iOS 2.6.5 | 29f00dd7872ada4bd14b90e5d49568a8 |
| iOS 3.x | 29f00dd7872ada4bd14b90e5d49568a8 |
| Android 2.3 | 29f0dd7872ada4bd14b90e5d49568a8 |
| Android 3.x | 29f00dd7872ada4bd14b90e5d49568a8 |

> Note: This process should **only** be applied to new tokens obtained from
> Android platforms, to compare to tokens from older app versions.

To account for this difference, developers should adapt the new account token as
shown below.

**JavaScript**

```js
function newToOld(token) {
  return token.split('').map(function (x, i) {
    return (x !== '0' || i % 2 == 1) ? x : '';
  }).join('');
}
```

**Python**

```python
def new_to_old(token):
    return ''.join(x for i, x in enumerate(token) if x != '0' or i % 2 == 1)
```

**Ruby**

```ruby
def new_to_old(token)
  token.split('').select.with_index { |c, i| (c != '0' or i % 2 == 1) }.join('')
end
```

**PHP**

<div>
{% highlight { "language": "php", "options": { "startinline": true } } %}
function newToOld($token) {
    $array = str_split($token);
    return implode('', array_map(function($char, $i) {
        return ($char !== '0' || $i % 2 == 1) ? $char : '';
    }, $array, array_keys($array)));
}
{% endhighlight %}
</div>


### Using the Status Bar

To help apps integrate aesthetically with the new system experience, all
``Window``s are now fullscreen-only in SDK 3.x. To keep the time-telling
functionality, developers should use the new ``StatusBarLayer`` API in their
`.load` handler.

> Note: Apps built with SDK 2.x will still keep the system status bar unless
> specified otherwise with `window_set_fullscreen(window, true)`. As a result,
> such apps that have been recompiled will be shifted up sixteen pixels, and
> should account for this in any window layouts.

```c
static StatusBarLayer *s_status_bar;
```

```c
static void main_window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);

  /* other UI code */

  // Set up the status bar last to ensure it is on top of other Layers
  s_status_bar = status_bar_layer_create();
  layer_add_child(window_layer, status_bar_layer_get_layer(s_status_bar));
}
```

By default, the status bar will look the same as it did on 2.x, minus the
battery meter.

![status-bar-default >{pebble-screenshot,pebble-screenshot--time-red}](/images/sdk/status-bar-default.png)

To display the legacy battery meter on the Basalt platform, simply add an
additional ``Layer`` after the ``StatusBarLayer``, and use the following code in
its ``LayerUpdateProc``.

```c
static void battery_proc(Layer *layer, GContext *ctx) {
  // Emulator battery meter on Aplite
  graphics_context_set_stroke_color(ctx, GColorWhite);
  graphics_draw_rect(ctx, GRect(126, 4, 14, 8));
  graphics_draw_line(ctx, GPoint(140, 6), GPoint(140, 9));

  BatteryChargeState state = battery_state_service_peek();
  int width = (int)(float)(((float)state.charge_percent / 100.0F) * 10.0F);
  graphics_context_set_fill_color(ctx, GColorWhite);
  graphics_fill_rect(ctx, GRect(128, 6, width, 4), 0, GCornerNone);
}
```

```c
static void main_window_load(Window *window) {
  Layer *window_layer = window_get_root_layer(window);
  GRect bounds = layer_get_bounds(window_layer);

  /* other UI code */

  // Set up the status bar last to ensure it is on top of other Layers
  s_status_bar = status_bar_layer_create();
  layer_add_child(window_layer, status_bar_layer_get_layer(s_status_bar));

  // Show legacy battery meter
  s_battery_layer = layer_create(GRect(bounds.origin.x, bounds.origin.y, 
                                      bounds.size.w, STATUS_BAR_LAYER_HEIGHT));
  layer_set_update_proc(s_battery_layer, battery_proc);
  layer_add_child(window_layer, s_battery_layer);
}
```

> Note: To update the battery meter more frequently, use ``layer_mark_dirty()``
> in a ``BatteryStateService`` subscription. Unless the current ``Window`` is
> long-running, this should not be neccessary.

The ``StatusBarLayer`` can also be extended by the developer in similar ways to
the above. The API also allows setting the layer's separator mode and
foreground/background colors:

```c
status_bar_layer_set_separator_mode(s_status_bar, 
                                            StatusBarLayerSeparatorModeDotted);
status_bar_layer_set_colors(s_status_bar, GColorClear, GColorWhite);
```

This results in a a look that is much easier to integrate into a color app.

![status-bar-color >{pebble-screenshot,pebble-screenshot--time-red}](/images/sdk/status-bar-color.png)


### Using PropertyAnimation

The internal structure of ``PropertyAnimation`` has changed, but it is still
possible to access the underlying ``Animation``:

```c
// SDK 2.x
Animation *animation = &prop_animation->animation;
animation = (Animation*)prop_animation;

// SDK 3.x
Animation *animation = property_animation_get_animation(prop_animation);
animation = (Animation*)prop_animation;
```

Accessing internal fields of ``PropertyAnimation`` has also changed. For
example, to access the ``GPoint`` in the `from` member of an animation:

```c
GPoint p;
PropertyAnimation *prop_anim;

// SDK 2.x
prop_animation->values.from.gpoint = p;

// SDK 3.x
property_animation_set_from_gpoint(prop_anim, &p);
```

Animations are now automatically freed when they have finished. This means that
code using ``animation_destroy()`` should be corrected to no longer do this
manually when building with SDK 3.x, which will fail. **SDK 2.x code must still
manually free Animations as before.**

Developers can now create complex synchronized and chained animations using the
new features of the Animation Framework. Read
{% guide_link graphics-and-animations/animations %}
to learn more.


### Accessing GBitmap Members

``GBitmap`` is now opaque, so accessing structure members directly is no longer
possible. However, direct references to members can be obtained with the new
accessor functions provided by SDK 3.x:

```c
static GBitmap *s_bitmap = gbitmap_create_with_resource(RESOURCE_ID_EXAMPLE_IMAGE);

// SDK 2.x
GRect image_bounds = s_bitmap->bounds;

// SDK 3.x
GRect image_bounds = gbitmap_get_bounds(s_bitmap);
```


### Drawing Rotated Bitmaps

<div class="alert alert--fg-white alert--bg-dark-red">
{% markdown %}
  The bitmap rotation API requires a significant amount of CPU power and will
  have a substantial effect on users' battery life.

  There will also be a large reduction in performance of the app and a lower
  framerate may be seen. Use alternative drawing methods such as 
  ``Draw Commands`` or [`GPaths`](``GPath``) wherever possible.
{% endmarkdown %%}
</div>

Alternatively, draw a ``GBitmap`` with a rotation angle and center point inside a
``LayerUpdateProc`` using ``graphics_draw_rotated_bitmap()``.


### Using InverterLayer

SDK 3.x deprecates the `InverterLayer` UI component which was primarily used
for ``MenuLayer`` highlighting. Developers can now make use of
`menu_cell_layer_is_highlighted()` inside a ``MenuLayerDrawRowCallback`` to
determine which text and selection highlighting colors they prefer.

> Using this for determining highlight behaviour is preferable to using
> ``menu_layer_get_selected_index()``. Row drawing callbacks may be invoked
> multiple times with a different highlight status on the same cell in order to
> handle partially highlighted cells during animation.
