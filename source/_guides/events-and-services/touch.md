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

title: Touch
description: |
  How to subscribe to touch events on platforms with a touchscreen.
guide_group: events-and-services
order: 10
related_examples:
  - title: Touch Thing
    url: https://github.com/coredevices/example-apps/tree/main/touch-thing
---

On hardware platforms with a touchscreen, the `TouchService` lets an app
receive touchdown, lift-off, and position updates as the user moves their
finger across the display. This is the same low-level event stream the system
itself uses, so apps can build draggable UI or free-form input on top of it.
Apps that want gestures rather than raw touches can use the built-in
[gesture recognizers](#gesture-recognizers), and apps that just want their
menus to scroll by touch can opt in to
[touch navigation](#touch-navigation) without handling any touch events at
all.

{% alert important %}
Touch input is currently **not supported in watchfaces**. While we work out how
we want to expose it, touch is intentionally restricted to watchapps - it is
easier to allow it later than to take it away once apps depend on it. For now,
only use the `TouchService` from a watchapp.
{% endalert %}


## Detecting Touch Support

A touchscreen is not present on every platform, and even when it is the user
can disable touch input from *Settings → Display → Touch*. Apps should call
``touch_service_is_enabled()`` before relying on touch input - typically from
the window's `appear` handler - and gracefully degrade if it returns `false`:

```c
static void main_window_appear(Window *window) {
  if (!touch_service_is_enabled()) {
    text_layer_set_text(s_status_layer,
                        "Touch is disabled. Enable it in Settings → Display.");
    return;
  }

  // Touch is available - subscribe and start the touch UI
  touch_service_subscribe(touch_handler, NULL);
}
```

`touch_service_is_enabled()` returns `false` on platforms without a
touchscreen, so a single check covers both the "no hardware" and the
"user-disabled" cases.

For code that should only be compiled on platforms with a touchscreen at all -
for example, an entire gesture recognizer that has no equivalent on
button-only hardware - use the `PBL_TOUCH` compile-time define:

```c
#if defined(PBL_TOUCH)
  touch_service_subscribe(touch_handler, NULL);
#else
  // Fall back to a button-based UI
  window_set_click_config_provider(window, click_config_provider);
#endif
```


## Subscribing to Touch Events

Touch events are delivered through a ``TouchServiceHandler`` callback. The
handler receives a pointer to a ``TouchEvent`` describing what happened, and
the context pointer that was registered with the subscription:

```c
static void touch_handler(const TouchEvent *event, void *context) {
  switch (event->type) {
    case TouchEvent_Touchdown:
      APP_LOG(APP_LOG_LEVEL_DEBUG, "Touchdown at %d, %d", event->x, event->y);
      break;
    case TouchEvent_PositionUpdate:
      APP_LOG(APP_LOG_LEVEL_DEBUG, "Move to %d, %d", event->x, event->y);
      break;
    case TouchEvent_Liftoff:
      APP_LOG(APP_LOG_LEVEL_DEBUG, "Liftoff at %d, %d", event->x, event->y);
      break;
  }
}
```

Subscribing to the service powers on the touch sensor; it stays on as long as
at least one app is subscribed and is automatically disabled again once the
last subscriber drops:

```c
// Receive touch events
touch_service_subscribe(touch_handler, NULL);
```

When the app no longer needs touch input - for example, when its main window
disappears - unsubscribe:

```c
touch_service_unsubscribe();
```


## Event Types

The ``TouchEventType`` field on each event identifies what the user just did:

| Event Type | Description |
|------------|-------------|
| ``TouchEvent_Touchdown`` | The user has just placed a finger on the screen. `x` and `y` are the initial contact position. |
| ``TouchEvent_PositionUpdate`` | An existing touch has moved. `x` and `y` are the new position. |
| ``TouchEvent_Liftoff`` | The user has just lifted their finger. `x` and `y` are the final position before lift-off. |

Coordinates are in the same screen-relative pixel space used everywhere else
in the UI, so they can be passed directly to drawing routines or compared
against ``Layer`` bounds.

A typical touch interaction starts with a single `TouchEvent_Touchdown`,
followed by zero or more `TouchEvent_PositionUpdate` events as the finger
moves, and ends with a single `TouchEvent_Liftoff`. Apps that want to track
gestures (taps, drags, swipes) can do this by hand - store the touchdown
position, watch the position updates, and decide what happened on lift-off -
but in most cases the built-in [gesture recognizers](#gesture-recognizers)
below do that work already.

Each ``TouchEvent`` also carries a `non_navigational` flag. It is set on
touches that arrive while no *interaction session* is active (see
[Touch Navigation](#touch-navigation) below) — the user is touching the
screen without having woken the watch first. Raw subscribers still receive
these events and can decide for themselves whether to honor them.


## Touch Navigation

Since firmware 4.32, the system can translate touches into the button-based
navigation model: tapping and swiping in a ``MenuLayer`` scrolls it and
activates rows, taps on an ``ActionBarLayer`` are zoned into up/select/down
button events, and ``ActionMenu`` items activate on tap. As of firmware 4.33
this *touch navigation* is enabled by default, and it is gated on an
**interaction session**: the user must press a button or wake the watch with
a gesture before touches navigate. This prevents accidental navigation from
brushing against an idle watchface.

Watchapps are **opted out** of touch navigation by default, so existing apps
behave exactly as before. To let the system drive your menus and scroll views
by touch, opt in once at startup:

```c
app_touch_navigation_enable(true);
```

With touch navigation enabled for the app, taps and swipes that don't hit a
touch-aware widget are bridged to button click events, so a plain
`click_config_provider` keeps working without any touch-specific code.

If one particular ``Window`` handles its own touch input - with a raw
subscription or with recognizers - take it out of the touch bridge so the
system doesn't consume its touches:

```c
window_set_touch_bridge_disabled(window, true);
```


## Gesture Recognizers

Rather than tracking touchdown/move/lift-off sequences by hand, apps can
create *recognizers* that watch the touch stream for one specific gesture and
report progress through a callback. Three recognizers are available:

| Recognizer | Constructor | Recognizes |
|------------|-------------|------------|
| Tap | ``tap_recognizer_create()`` | A single tap. Read the location with ``tap_recognizer_get_tap_point()``. |
| Pan | ``pan_recognizer_create()`` | A drag locked to one axis (``PanAxis_Horizontal`` or ``PanAxis_Vertical``). Read movement with ``pan_recognizer_get_total_delta()``, ``pan_recognizer_get_delta_since_start()``, ``pan_recognizer_get_delta_since_prev()`` and ``pan_recognizer_get_velocity()``. |
| Swipe | ``swipe_recognizer_create()`` | A fast, straight flick in one of the directions in the given ``SwipeDirection`` mask. Read the result with ``swipe_recognizer_get_direction()`` and ``swipe_recognizer_get_velocity()``. |

Each recognizer reports ``RecognizerEvent_Started``,
``RecognizerEvent_Updated``, ``RecognizerEvent_Completed`` and
``RecognizerEvent_Cancelled`` events to its ``RecognizerEventCb``.

Recognizers are attached to a window with ``window_attach_recognizer()``. The
window takes ownership and destroys attached recognizers when it unloads, so
in the common case there is nothing to clean up manually
(``recognizer_destroy()`` exists for recognizers that were never attached).
Remember to also disable the window's touch bridge, or the system will
consume the touches before your recognizers see them.

This example scrolls a custom ``ScrollLayer`` by finger — something a bare
`ScrollLayer` does not do on its own:

```c
static ScrollLayer *s_scroll;
static int16_t s_base;  // content offset committed on Complete

static void pan_handler(const Recognizer *recognizer, RecognizerEvent event) {
  switch (event) {
    case RecognizerEvent_Updated: {
      // delta_since_start is (0, 0) at Start, so the content does not jump
      GPoint d = pan_recognizer_get_delta_since_start(recognizer);
      scroll_layer_set_content_offset(s_scroll, GPoint(0, s_base + d.y), false);
      break;
    }
    case RecognizerEvent_Completed:
      // Commit the new offset
      s_base = scroll_layer_get_content_offset(s_scroll).y;
      break;
    case RecognizerEvent_Cancelled:
      // Roll back to the last committed offset
      scroll_layer_set_content_offset(s_scroll, GPoint(0, s_base), true);
      break;
    default:
      break;
  }
}

static void main_window_load(Window *window) {
  Layer *root = window_get_root_layer(window);
  s_scroll = scroll_layer_create(layer_get_bounds(root));
  scroll_layer_set_content_size(s_scroll,
      GSize(layer_get_bounds(root).size.w, total_content_height));
  // Add custom row layers as children of s_scroll here
  layer_add_child(root, scroll_layer_get_layer(s_scroll));

  // Handle this window's touches ourselves instead of the system bridge
  window_set_touch_bridge_disabled(window, true);

  // The window owns the recognizer and destroys it when the window unloads
  Recognizer *pan = pan_recognizer_create(pan_handler, NULL, PanAxis_Vertical);
  window_attach_recognizer(window, pan);
}
```

When several recognizers watch the same window, they are evaluated
exclusively by default: the first one to recognize its gesture wins. Use
``recognizer_set_simultaneous_with()`` to allow two recognizers to evaluate
at the same time, or ``recognizer_set_fail_after()`` to hold one back until
another has failed (e.g. only treat a touch as a tap once the swipe
recognizer has given up).

Note that on touch hardware a ``MenuLayer`` already scrolls and activates by
touch when the app has opted in to touch navigation. Recognizers are for
interactions the built-in widgets don't provide, such as custom menus, drags,
or acting on raw taps and swipes.


## Backlight Behavior

Each touch event triggers the backlight the same way a wrist flick or button
press would - the light flashes on for the system auto-off interval and then
fades out. This keeps the screen lit naturally while the user is actively
interacting, without keeping the backlight pinned on between taps. There is
no need to call the [Light API](/guides/events-and-services/light) manually
to achieve this; subsequent touches will re-trigger the backlight on their
own.


## Battery Considerations

The touch sensor is an active component and draws power continuously while
enabled. Subscribe to the touch service only while the app's UI actually needs
touch input, and unsubscribe as soon as it doesn't - for example, in the
window `disappear` handler, or when navigating to a screen that uses buttons
instead.
