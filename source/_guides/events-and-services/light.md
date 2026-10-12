---
# Copyright 2026 Core Devices LLC
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

title: Backlight
description: |
  How to trigger the backlight, force it on, and - on hardware with an RGB
  backlight - tint it.
guide_group: events-and-services
order: 9
related_examples:
  - title: RGB Backlight Thing
    url: https://github.com/coredevices/example-apps/tree/main/rgb-backlight-thing
---

The Light API gives an app limited control over the watch backlight. An app can
ask the system to flash the backlight as if the user had performed a wrist
gesture, or force it on for as long as it needs. On hardware with an RGB
backlight, the same API can also tint that backlight any color the user can
render in their UI.

All of these calls operate on top of the user's normal backlight settings (auto
on-shake, brightness, etc.), so apps don't need to worry about overriding the
user's preferences permanently.


## Triggering the Backlight

The simplest and most common use of the Light API is to trigger the backlight
exactly as a wrist flick would. The light comes on, stays on for the system
auto-off interval, and then fades out:

```c
// Turn the backlight on for the standard auto-off interval
light_enable_interaction();
```

This is the recommended entry point for most apps. It respects the user's
backlight setting (it does nothing if the user has the backlight disabled) and
does not require a follow-up call to turn the light back off.


## Forcing the Backlight On

If an app needs the backlight on for an extended interaction - for example,
during a flashlight feature or while the user is doing something with both
hands - it can pin it on:

```c
// Force the backlight on
light_enable(true);
```

The backlight stays on until the app explicitly returns control to the
automatic system:

```c
// Hand control back to the system's auto-off behavior
light_enable(false);
```

> Holding the backlight on draws significantly more power than letting it
> auto-off. The system also dims the backlight automatically when the battery
> is low to protect the user's remaining runtime, so a forced-on backlight is
> not a guarantee of full brightness.

To check whether the backlight is currently on, use:

```c
if (light_is_on()) {
  // The backlight is currently lit
}
```


## Reacting to Backlight Changes

The ``BacklightService`` tells an app when the backlight turns on or off,
whether the user flicked their wrist, pressed a button or the auto-off timer
ran out. A watchface can use it to switch to a brighter color scheme while the
light is on, or to pause an animation when the display is no longer being
looked at:

```c
static void backlight_handler(bool on) {
  // on is true when the backlight has just turned on,
  // false when it has turned fully off
  layer_mark_dirty(s_canvas_layer);
}

// Subscribe
backlight_service_subscribe(backlight_handler);

// Later, stop receiving events
backlight_service_unsubscribe();
```

The handler is called once per transition. Any state other than fully off,
including the fade-out, counts as on. Use ``light_is_on()`` to read the
current state without subscribing.

``backlight_service_subscribe()`` is available on Pebble 2 Duo (flint),
Pebble Time 2 (emery) and Pebble Round 2 (gabbro). On aplite, basalt, chalk
and diorite the SDK compiles it to a no-op, so the handler is never called.


## Tinting the Backlight (RGB Hardware Only)

On hardware with an RGB backlight, the backlight color can be set to any
``GColor`` value. The color persists for as long as the app is in the
foreground, then resets to the user's default when the app exits or is
preempted (for example, by an incoming notification modal).

```c
// Tint the backlight red
light_set_color(GColorRed);
```

`light_set_color()` takes a ``GColor``, which on current hardware quantizes
to the 64-color palette the UI uses. For more control over the exact tint -
for example, to match a brand color or blend between two palette entries -
use `light_set_color_rgb888()`, which takes a 24-bit RGB value packed into a
`uint32_t` as `0x00RRGGBB`:

```c
// Tint the backlight with an exact RGB color (teal)
light_set_color_rgb888(0x0088CC);
```

Once set, the tint persists for the rest of the app's foreground session -
every subsequent backlight trigger will use that color until the app changes
it again or exits. To return to the user's chosen default mid-session, call:

```c
// Restore the user's default backlight color
light_set_system_color();
```

This is important if the app uses different colors for different states (for
example, red for an alert and the user default the rest of the time): without
an explicit `light_set_system_color()` call the alert color will stick around
for every subsequent backlight flash. The system does reset the color
automatically when the app exits or is preempted, so there's no need to call
`light_set_system_color()` purely on the way out.

On hardware without an RGB backlight these two calls are no-ops and can be
left in unconditionally; there's no need to wrap them in a preprocessor guard
just to compile against other platforms. For cases where a whole block of
color-specific logic should be excluded on non-RGB platforms, the
`PBL_RGB_BACKLIGHT` compile-time define is present on platforms that have an
RGB backlight:

```c
#if defined(PBL_RGB_BACKLIGHT)
  // Use a different tint per app state
  light_set_color(is_alert ? GColorRed : GColorWhite);
#endif
light_enable_interaction();
```

Tinting only changes the *color* of the backlight; the backlight still needs
to be on for the user to see it. Combine `light_set_color()` with
`light_enable_interaction()` or `light_enable(true)` so the user
actually sees the new color:

```c
// Flash the backlight red for the system auto-off interval
light_set_color(GColorRed);
light_enable_interaction();
```


## Battery Considerations

The backlight is one of the most power-hungry components on the watch.
Triggering it through `light_enable_interaction()` for short user
interactions is generally fine, but holding it on for long periods with
`light_enable(true)` will noticeably reduce battery life. Use the forced-on
mode only when the feature genuinely requires it, and make sure to release
control with `light_enable(false)` as soon as the user is done.
