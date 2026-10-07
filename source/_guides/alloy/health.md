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

title: Health
description: |
  Read steps, sleep, activities and heart rate data from Pebble Health in
  Alloy apps.
guide_group: alloy
order: 17
---

The `Health` class gives Alloy apps access to Pebble Health: current and
historical step counts, sleep, calories, distance, detected activities, and
heart rate. It was added in SDK 4.33 and requires firmware 4.32 or later.

> **Note**: Health data is only available while the user has Pebble Health
> enabled in the mobile app, and heart rate metrics additionally require a
> watch with a heart rate monitor (Pebble Time 2). Well-behaved apps check
> [availability](#checking-availability) before reading.

All times passed to and returned by the Health API are JavaScript
milliseconds — pass `Date` objects or millisecond timestamps.

## Reading Current Values

`Health.metric.get()` returns the current (today's) value of a metric:

```js
import Health from "pebble/health";

console.log(`Steps today: ${Health.metric.get("step count")}`);
console.log(`Heart rate: ${Health.metric.get("heart rate")} BPM`);
```

| Metric | Description |
|--------|-------------|
| `"step count"` | Steps taken today |
| `"active seconds"` | Seconds spent active today |
| `"walked distance"` | Distance walked today, in meters |
| `"sleep seconds"` | Seconds slept |
| `"sleep restful seconds"` | Seconds of restful (deep) sleep |
| `"resting calories"` | Resting kilocalories burned today |
| `"active calories"` | Active kilocalories burned today |
| `"heart rate"` | Filtered heart rate, in BPM |
| `"heart rate raw"` | Raw, unfiltered heart rate, in BPM |

## Checking Availability

Not every metric is available on every watch, for every time range, or with
the user's current permissions. `Health.metric.accessible()` returns a
bitmask of the flags in `Health.access`:

```js
import Health from "pebble/health";

const now = Date.now();
const access = Health.metric.accessible({
    metric: "heart rate",
    start: now,
    end: now
});

if (access & Health.access.available) {
    console.log(`Heart rate: ${Health.metric.get("heart rate")} BPM`);
}
```

| Flag | Meaning |
|------|---------|
| `Health.access.available` | Values can be read for the requested range |
| `Health.access.permission` | The user has granted this app access to health data |
| `Health.access.supported` | The watch supports this metric |
| `Health.access.data` | Samples exist in the requested range |

## Querying History

`Health.metric.query()` reads sums and averages over a time range. With no
`start` and `end`, it returns today's total:

```js
import Health from "pebble/health";

// Today's total (same as Health.metric.get for cumulative metrics)
const today = Health.metric.query({ metric: "step count" });

// Average daily steps over the past week
const WEEK = 7 * 24 * 60 * 60 * 1000;
const weeklyAverage = Health.metric.query({
    metric: "step count",
    start: Date.now() - WEEK,
    end: Date.now(),
    aggregation: "average",
    scope: "daily"
});

console.log(`Today: ${today}, daily average: ${weeklyAverage}`);
```

| Option | Values | Description |
|--------|--------|-------------|
| `metric` | See [metric table](#reading-current-values) | The metric to query. Required. |
| `start`, `end` | `Date` or milliseconds | Time range. Provide both or neither — with neither, the query covers today. |
| `aggregation` | `"sum"` (default), `"average"`, `"min"`, `"max"` | How samples in the range are combined. `min`/`max` are only stored for recent history. |
| `scope` | `"once"` (default), `"daily"`, `"weekly"`, `"weekday or weekend"` | Which days contribute: every day in the range at once, or averaged per-day, per-week, or by weekday/weekend. |

## Health Events

Subscribe to the `"health"` event on the `watch` global to be told when new
data arrives. The listener receives a string describing what changed:

```js
watch.addEventListener("health", what => {
    if (what === "movement")
        console.log(`Steps now: ${Health.metric.get("step count")}`);
});
```

| Subtype | Meaning |
|---------|---------|
| `"significant"` | All data should be considered outdated (e.g. day rollover) — re-read everything |
| `"movement"` | Step, distance or active-time values changed |
| `"sleep"` | Sleep values changed |
| `"metric"` | A [metric alert](#metric-alerts) threshold was crossed |
| `"heart rate"` | A new heart rate reading is available |
| `"heart rate variability"` | A new heart rate variability reading is available |

## Metric Alerts

Instead of polling, register a threshold with `Health.metric.Alert`. When
the metric crosses the threshold, a `"metric"` health event fires:

```js
import Health from "pebble/health";

const alert = new Health.metric.Alert({
    metric: "heart rate",
    threshold: 120
});

watch.addEventListener("health", what => {
    if (what === "metric")
        console.log("Heart rate above 120!");
});
```

Call `alert.close()` to cancel the alert. Alerts are also disposable, so a
`using` declaration closes them automatically at the end of the scope:

```js
using alert = new Health.metric.Alert({ metric: "step count", threshold: 10000 });
```

## Activities

Pebble Health detects activities like sleeping, walking and running.
`Health.activity.get()` returns a bitmask of what the user is doing right
now, and `Health.activity.iterate()` walks through past (or upcoming
scheduled) activity sessions:

```js
import Health from "pebble/health";

// What is the user doing right now?
if (Health.activity.get() & Health.activity.run)
    console.log("Running!");

// List today's walks and runs
const DAY = 24 * 60 * 60 * 1000;
Health.activity.iterate({
    activities: Health.activity.walk | Health.activity.run,
    start: Date.now() - DAY,
    end: Date.now(),
    callback(activity, start, end) {
        const minutes = Math.round((end - start) / 60000);
        const name = (activity === Health.activity.run) ? "Run" : "Walk";
        console.log(`${name}: ${minutes} minutes`);
        return true;    // keep iterating; return false to stop
    }
});
```

The available activity constants are `Health.activity.sleep`,
`restfulSleep`, `walk`, `run` and `openWorkout`. Use
`Health.activity.accessible({activities, start, end})` to check access the
same way as for metrics.

## Heart Rate Sampling

By default the system samples heart rate automatically, more often during
intense activity and less often at rest. An app that needs more frequent
readings can request a shorter sample period (in milliseconds):

```js
import Health from "pebble/health";

// Request a heart rate sample every second
Health.heartRate.samplePeriod = 1000;

// ...and restore automatic sampling when done
Health.heartRate.samplePeriod = 0;
```

The system treats the request as a suggestion, and shared use by other apps
may result in a different effective rate. Always set the period back to `0`
when your app no longer needs fast sampling. If the app exits without doing
so, the request lingers for a while — `Health.heartRate.samplePeriodExpiration`
reports how long (in milliseconds) it remains in effect.

## Minute-by-Minute History

`Health.history.byMinute()` returns detailed per-minute records:

```js
import Health from "pebble/health";

const HOUR = 60 * 60 * 1000;
const minutes = Health.history.byMinute({
    length: 60,
    start: Date.now() - HOUR,
    end: Date.now()
});

for (const record of minutes) {
    if (!record)
        continue;   // minutes with no valid data are left undefined
    console.log(`Steps: ${record.steps}, HR: ${record.heartRate}`);
}
```

Each record has `steps`, `orientation`, `vmc` (vector magnitude counts, a
measure of movement intensity), `light` (ambient light level) and
`heartRate`. The returned array also carries `start` and `end` properties
with the actual time range covered.

## Measurement System

To display distances in the user's preferred units, ask which measurement
system they chose for a metric in the mobile app:

```js
const system = Health.displayMeasurementSystem("walked distance");
// "metric", "imperial", or undefined if the user hasn't chosen
```

## See Also

* {% guide_link alloy/device-info "Device Info & App Lifecycle" %} — the
  other `watch` events
* {% guide_link alloy/sensors-and-input "Sensors and Input" %} — live
  accelerometer and battery data
