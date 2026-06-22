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
itself uses, so apps can build their own gesture recognizers, draggable UI, or
free-form input on top of it.

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
gestures (taps, drags, swipes) generally store the touchdown position, watch
the position updates, and decide what happened on lift-off.


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
