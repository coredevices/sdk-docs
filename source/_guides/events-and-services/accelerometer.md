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

title: Accelerometer
description: |
  How to use data and simple tap gestures from the onboard accelerometer.
guide_group: events-and-services
order: 0
related_docs:
  - AccelerometerService
related_examples:
  - title: Feature Accel Discs
    url: https://github.com/pebble-examples/feature-accel-discs
---

The acceleromter sensor is included in every Pebble watch, and allows collection
of acceleration and orientation data in watchapps and watchfaces. Data is
available in two ways, each suitable to different types of watchapp:

* Taps events - Fires an event whenever a significant tap or shake of the watch
  occurs. Useful to 'shake to view' features.

* Data batches - Allows collection of data in batches at specific intervals.
  Useful for general accelerometer data colleciton.

As a significant source of regular callbacks, the accelerometer should be used
as sparingly as possible to allow the watch to sleep and conserve power. For
example, receiving data in batches once per second is more power efficient than
receiving a single sample 25 times per second.


## About the Pebble Accelerometer

The Pebble accelerometer is oriented according to the diagram below, showing the
direction of each of the x, y, and z axes.

![accel-axes](/images/guides/pebble-apps/sensors/accel.png)

In the API, each axis value contained in an ``AccelData`` sample is measured in
milli-Gs. The accelerometer is calibrated to measure a maximum acceleration of
±4G. Therefore, the range of possible values for each axis is -4000 to +4000.

The ``AccelData`` sample object also contains a `did_vibrate` field, set to
`true` if the vibration motor was active during the sample collection. This
could possibly contaminate those samples due to onboard vibration, so they
should be discarded. Lastly, the `timestamp` field allows tracking of obtained
accelerometer data over time.


## Using Taps

Adding a subscription to tap events allows a developer to react to any time the
watch is tapped or experiences a shake along one of three axes. Tap events are
received by registering an ``AccelTapHandler`` function, such as the one below:

```c
static void accel_tap_handler(AccelAxisType axis, int32_t direction) {
  // A tap event occured

}
```

The `axis` parameter describes which axis the tap was detected along. The
`direction` parameter is set to `1` for the positive direction, and `-1` for the
negative direction.

A subscription can be added or removed at any time. While subscribed,
`accel_tap_handler` will be called whenever a tap event is fired by the
accelerometer. Adding a subscription is simple:

```c
// Subscribe to tap events
accel_tap_service_subscribe(accel_tap_handler);
```

```c
// Unsubscribe from tap events
accel_tap_service_unsubscribe();
```


## Using Data Batches

Accelerometer data can be received in batches at a chosen sampling rate by
subscribing to the Accelerometer Data Service at any time:

```c
uint32_t num_samples = 3;  // Number of samples per batch/callback

// Subscribe to batched data events
accel_data_service_subscribe(num_samples, accel_data_handler);
```

The ``AccelDataHandler`` function (called `accel_data_handler` in the example
above) is called when a new batch of data is ready for consumption by the
watchapp. The rate at which these occur is dictated by two things:

* The sampling rate - The number of samples the accelerometer device measures
  per second. One value chosen from the ``AccelSamplingRate`` `enum`.

* The number of samples per batch.

Some simple math will determine how often the callback will occur. For example,
at the ``ACCEL_SAMPLING_50HZ`` sampling rate, and specifying 10 samples per
batch will result in five calls per second.

When an event occurs, the acceleromater data can be read from the ``AccelData``
pointer provided in the callback. An example reading the first set of values is
shown below:

```c
static void accel_data_handler(AccelData *data, uint32_t num_samples) {
  // Read sample 0's x, y, and z values
  int16_t x = data[0].x;
  int16_t y = data[0].y;
  int16_t z = data[0].z;

  // Determine if the sample occured during vibration, and when it occured
  bool did_vibrate = data[0].did_vibrate;
  uint64_t timestamp = data[0].timestamp;

  if(!did_vibrate) {
    // Print it out
    APP_LOG(APP_LOG_LEVEL_INFO, "t: %llu, x: %d, y: %d, z: %d",
                                                          timestamp, x, y, z);
  } else {
    // Discard with a warning
    APP_LOG(APP_LOG_LEVEL_WARNING, "Vibration occured during collection");
  }
}
```

The code above will output the first sample in each batch to app logs, which
will look similar to the following:

```nc|text
[15:33:18] -data-service.c:21> t: 1449012797098, x: -111, y: -280, z: -1153
[15:33:18] -data-service.c:21> t: 1449012797305, x: -77, y: 40, z: -1014
[15:33:18] -data-service.c:21> t: 1449012797507, x: -60, y: 4, z: -1080
[15:33:19] -data-service.c:21> t: 1449012797710, x: -119, y: -55, z: -921
[15:33:19] -data-service.c:21> t: 1449012797914, x: 628, y: 64, z: -506
```