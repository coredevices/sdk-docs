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

title: Device Info and App Events
description: |
  Query watch and screen properties, respond to app lifecycle events, and
  control the backlight in Alloy apps.
guide_group: alloy
order: 16
---

Alloy exposes information about the watch and screen through the `watch`,
`screen`, and `device` globals, delivers app lifecycle events through `watch`,
and lets you control the backlight with `watch.light()`.

> **Platform Support**: These APIs are available on Emery (Pebble Time 2) and
> Gabbro (Pebble Round 2).

## Watch Information

The `watch` global describes the device and the user's preferences:

```js
console.log(`watch.model ${watch.model}`);
console.log(`firmware ${watch.firmwareVersion.major}.${watch.firmwareVersion.minor}.${watch.firmwareVersion.patch}`);
console.log(`user prefers ${watch.hour12 ? "12" : "24"} hour display`);
```

| Property | Description |
|----------|-------------|
| `watch.model` | The watch model identifier. |
| `watch.firmwareVersion` | Object with `major`, `minor`, and `patch` numbers. |
| `watch.hour12` | `true` if the user prefers a 12-hour clock, `false` for 24-hour. |
| `watch.launch` | How the app was launched: `reason` and `arguments`. |
| `watch.wake` | Present when launched by a wakeup; see {% guide_link alloy/wakeups %}. |

## Screen Properties

The `screen` global describes the display:

```js
console.log(`screen ${screen.width} x ${screen.height}`);
console.log(`round ${screen.round}, color ${screen.color}`);
```

| Property | Description |
|----------|-------------|
| `screen.width` | Display width in pixels. |
| `screen.height` | Display height in pixels. |
| `screen.round` | `true` on round displays (Gabbro). |
| `screen.color` | `true` on color displays. |

## Device Sensors

The `device.sensor` object reports which sensors are available, so you can
feature-detect before using one:

```js
const hasTouch = device.sensor.Touch ? true : false;
console.log(`touch available ${hasTouch}`);
```

## App Lifecycle and Display Events

Subscribe to app events on `watch` with `addEventListener`:

```js
watch.addEventListener("willFocus", inFocus => {
    console.log(`willFocus with inFocus ${inFocus}`);
});

watch.addEventListener("didFocus", inFocus => {
    console.log(`didFocus with inFocus ${inFocus}`);
});

watch.addEventListener("resize", progress => {
    console.log(`screen resized to ${screen.width} x ${screen.height} at progress ${progress}`);
});
```

| Event | Description |
|-------|-------------|
| `"willFocus"` | The app is about to gain or lose focus. The handler receives `inFocus`. |
| `"didFocus"` | The app has gained or lost focus. The handler receives `inFocus`. |
| `"resize"` | The drawable area is changing size (for example during an animation). The handler receives the animation `progress`. |

## Controlling the Backlight

Use `watch.light()` to control the backlight:

```js
watch.light(true);   // force the backlight on
watch.light(false);  // turn the backlight off

watch.light();       // turn on temporarily, as if the user interacted
```

Calling `watch.light()` with no argument turns the backlight on for the
standard auto-off interval, just like a button press or shake would. Passing a
boolean forces the backlight on or off.

> **Note**: Holding the backlight on draws significantly more power than
> letting it auto-off. Only force it on for short, deliberate interactions.

See the
[`helloinfo`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloinfo),
[`helloappevents`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloappevents),
and
[`hellolight`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellolight)
examples for complete projects.
