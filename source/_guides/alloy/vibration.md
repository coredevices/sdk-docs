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

title: Vibration
description: |
  Provide haptic feedback in Alloy apps using the vibration motor.
guide_group: alloy
order: 15
---

The `Vibes` class drives the watch's vibration motor, letting your Alloy app
provide haptic feedback. It offers a set of standard pulses as well as
custom vibration patterns.

> **Platform Support**: Vibration is available on Emery (Pebble Time 2) and
> Gabbro (Pebble Time 2 round).

## Standard Pulses

```js
import Vibes from "pebble/vibes";

Vibes.shortPulse();
Vibes.longPulse();
Vibes.doublePulse();
```

| Method | Description |
|--------|-------------|
| `Vibes.shortPulse()` | A single short vibration. |
| `Vibes.longPulse()` | A single long vibration. |
| `Vibes.doublePulse()` | Two short vibrations. |

## Custom Patterns

Pass an array of millisecond durations to `pattern()`. Durations alternate
between *on* and *off*, starting with *on*:

```js
import Vibes from "pebble/vibes";

// on 100ms, off 100ms, on 150ms, off 50ms, on 50ms, off 150ms, on 1000ms
Vibes.pattern([100, 100, 150, 50, 50, 150, 1000]);
```

## Cancelling

Stop any ongoing vibration immediately:

```js
Vibes.cancel();
```

> **Note**: Vibration draws power and can be disruptive. Use it sparingly, and
> respect the user's Quiet Time settings for non-essential feedback.

See the
[`hellovibes` example](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellovibes)
for a complete project.
