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

title: Announcing Pebble SDK 4.3
author: jonb
tags:
- Freshly Baked
---

Things have been a bit 'quiet' recently, but we're back with another fresh
Pebble SDK! In this release we've included one of the most frequently requested
APIs, exposed the raw HRM sensor value, released PebbleKit 4.0, plus added an
exciting new BLE HRM mode.


## It's. Oh. So quiet. Ssshhhhhh.

We've added an often requested method for developers to detect if *Quiet Time*
is enabled. To say that we had a lot of requests for this would be an
understatement.

*Quiet Time* can be enabled manually, via calendar events, or via scheduled
times, so we've made a simple method for querying whether it's currently active.

All you need to do is check each minute if it's active. This is easily done
within the tick event, as follows:

```c
static void handle_tick(struct tm *tick_time, TimeUnits units_changed) {
  if (units_changed & MINUTE_UNIT) {
    if (quiet_time_is_active()) {
      // It's nice and quiet
    } else {
      // Starts another big riot
    }
  }
}
```

You may also peek this value, for example, to prevent your application from
vibrating during *Quiet Time*:

```c
static void do_vibration() {
  if (!quiet_time_is_active()) {
    vibes_short_pulse();
  }
}
```


## Raw HRM BPM

The Pebble [Health API](``HealthService``) now exposes the raw BPM value from
the Heart Rate Monitor sensor. This raw value is not filtered and is useful for
applications which need to display the real-time sensor value, similar to the
Pebble Workout app.

For example, in order to peek the current real-time HRM sensor, you would do the
following:

```c
HealthServiceAccessibilityMask hr = health_service_metric_accessible(HealthMetricHeartRateRawBPM, time(NULL), time(NULL));
if (hr & HealthServiceAccessibilityMaskAvailable) {
  HealthValue val = health_service_peek_current_value(HealthMetricHeartRateRawBPM);
  if(val > 0) {
    // Display raw HRM value
    static char s_hrm_buffer[8];
    snprintf(s_hrm_buffer, sizeof(s_hrm_buffer), "%lu BPM", (uint32_t)val);
    text_layer_set_text(s_hrm_layer, s_hrm_buffer);
  }
}
```

Find out more in the
{% guide_link events-and-services/hrm "Heart Rate Monitor API guide" %}.


## PebbleKit 4.0

PebbleKit for [iOS](https://github.com/pebble/pebble-ios-sdk/) and
[Android](https://github.com/pebble/pebble-android-sdk/) facilitates
communication between Pebble watchapps and 3rd party companion phone apps.
Version 4.0 introduces a number of new features and bug fixes, including:

* Support for Pebble 2 *(required for iOS only)*
* Removal of Bluetooth Classic (iOS)
* Sports API - Support 3rd party HRM
* Sports API - Custom data field and label
* Sports API - Helper object to simplify usage, and minimize updates via
Bluetooth

For further information about the specific platform changes, view the full
[iOS](https://github.com/pebble/pebble-ios-sdk/), or
[Android](https://github.com/pebble/pebble-android-sdk/) changelogs.


## BLE HRM Mode

Ever wanted to use your *Pebble 2 HRM* as a dedicated BLE HRM device with your
favourite mobile fitness app? Well now you can! Firmware 4.3 now implements the
standard
[Bluetooth Heart Rate Service profile](https://www.bluetooth.org/docman/handlers/downloaddoc.ashx?doc_id=239866).
In order to enable this profile, users must enable 'Pebble Health', then enable
'Heart Rate Monitoring' within the `Pebble Health` settings within the Pebble
mobile app.

Developers who are looking to integrate directly with this profile should be
aware of the following:

The Heart Rate Service UUID will be present in the advertising payload of
Pebble, but you must open the Bluetooth settings on the Pebble to make it
advertise and be discoverable over Bluetooth.

Because it's highly likely that the Pebble is already connected to the phone, it
will not be advertising. Therefore, we recommend that your mobile app also
enumerates already connected devices, to see if any of them support the Heart
Rate Service. This is in addition to scanning for advertisements to find new
devices that support HRS. By enumerating connected devices, you improve the user
experience: users will not have to go into the Bluetooth settings menu on Pebble
if their Pebble is already connected to the phone.

The first time an application subscribes to the Heart Rate Measurement
characteristic, a UI prompt will appear on the Pebble, asking the user to allow
sharing of their heart rate data. This permission is stored for the duration of
the Bluetooth connection.

When HR data sharing is active, the HR sensor will run continuously at ~1Hz
sample rate. This means there is a significant battery impact when using this
feature for an extended period of time.

When all applications have unsubscribed from the Heart Rate Measurement
characteristic, the HR sensor automatically returns to its default state.

Mobile apps should unsubscribe from the Heart Rate Measurement characteristic as
soon as the data is no longer required. For example, a workout app should
unsubscribe when the workout has finished and/or the application is exited.

If the Heart Rate Service is used continuously for a prolonged period of time
(currently 4hrs), a notification is presented on the watch to remind the user
that the HR data is still being shared.

The user can stop sharing HRM data from *Settings > Bluetooth > Device*. If the
user chooses to stop sharing, the Bluetooth connection is briefly disconnected
and reconnected to forcefully remove all subscribers. Unfortunately the
Bluetooth GATT specification does not provide a better mechanism for a service
to unsubscribe subscribers, only subscribers can unsubscribe themselves.

Service Characteristics Notes:

* 'Sensor Contact' field is used.
* 'Body Sensor' characteristic is used. The value is constant though (It will
read "Wrist" / 0x02)
* 'RR Interval' is currently NOT used.
* 'Energy Expended' field is currently NOT used.
* 'Heart Rate Control Point' characteristic is currently NOT used.

## What's Next

Check out the [release notes](/sdk/changelogs/4.3/) for a full list of
changes and fixes that were included in SDK 4.3.

Let us know on [Twitter]({{ site.links.twitter }}) if you built something
cool using the new APIs! We'd love to hear about your experiences with the SDK.

Happy Hacking!

Team Pebble
