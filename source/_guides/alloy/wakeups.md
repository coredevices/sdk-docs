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

title: Wakeups
description: |
  Schedule your Alloy app to launch at a future time using wakeups.
guide_group: alloy
order: 14
---

Wakeups let your Alloy app schedule itself to launch at a future time, even if
it isn't running. When the wakeup fires, the system launches your app and you
can read the wakeup details to know why it was started.

> **Platform Support**: Wakeups are available on Emery (Pebble Time 2) and
> Gabbro (Pebble Time 2 round).

## Scheduling a Wakeup

Import the `WakeUp` class and call `schedule()` with a timestamp (in
milliseconds, as returned by `Date.now()`), a numeric `cookie` of your choice,
and whether the user should be notified if the wakeup is missed:

```js
import WakeUp from "pebble/wakeup";

// Fire 3 seconds from now
const id = WakeUp.schedule(Date.now() + 3000, 12345678, false);
console.log(`Scheduled WakeUp id ${id}`);
```

`schedule()` returns an `id` you can later use to query or cancel the wakeup.
Persist the `id` (for example with `localStorage`) if you need it across
launches.

## Methods

| Method | Description |
|--------|-------------|
| `WakeUp.schedule(time, cookie, notifyIfMissed)` | Schedule a wakeup at `time` (ms). `cookie` is a number passed back to your app. `notifyIfMissed` shows a missed-event notification if the wakeup couldn't fire. Returns an `id`. |
| `WakeUp.cancel(id)` | Cancel a previously scheduled wakeup. |
| `WakeUp.query(id)` | Return a `{ time, scheduled }` object describing the wakeup - `time` is the scheduled time in ms and `scheduled` is `true` if it is still pending - or a falsy value if it no longer exists. |

## Detecting a Wakeup Launch

When your app is launched by a wakeup, `watch.wake` is set and contains the
wakeup's `id` and `cookie`:

```js
console.log(`Launch reason ${watch.launch.reason}, arguments ${watch.launch.arguments}`);

if (watch.wake) {
    console.log(`Launched by wakeup id ${watch.wake.id}, cookie ${watch.wake.cookie}`);
}
```

## Receiving a Wakeup While Running

If a wakeup fires while your app is already running, it is delivered as a
`"wakeup"` event on `watch`:

```js
watch.addEventListener("wakeup", wake => {
    console.log(`wakeup id ${wake.id} occurred while running`);
    WakeUp.cancel(wake.id);
});
```

## Managing Stored Wakeups

Because a wakeup `id` outlives a single launch, it's good practice to validate
a stored `id` on startup and discard it if the wakeup is gone or stale:

```js
const id = localStorage.getItem("wakeid");
if (id) {
    const wakeup = WakeUp.query(id);
    if (!wakeup) {
        // The wakeup no longer exists
        localStorage.removeItem("wakeid");
    } else if (wakeup.time < Date.now()) {
        // The wakeup is in the past; cancel it
        WakeUp.cancel(id);
        localStorage.removeItem("wakeid");
    }
}
```

See the
[`hellowakeup` example](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellowakeup)
for a complete project.
