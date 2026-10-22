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

title: Compass
description: |
  How to use data from the Compass API to determine direction.
guide_group: events-and-services
order: 3
related_docs:
  - CompassService
related_examples:
  - title: Feature Compass
    url: https://github.com/pebble-examples/feature-compass
  - title: Official Compass Watchapp
    url: https://github.com/pebble-hacks/pebble-compass
---

The ``CompassService`` combines data from Pebble's accelerometer and
magnetometer to automatically calibrate the compass and produce a
``CompassHeading``, containing an angle measured relative to magnetic north.

The compass service provides magnetic north and information about its status 
and accuracy through the ``CompassHeadingData`` structure.


## Calibration

The compass service requires an initial calibration before it can return
accurate results. Calibration is performed automatically by the system when
first required. The [`compass_status`](``CompassHeadingData``) field indicates
whether the compass service is calibrating. To help the calibration process, the
app should show a message to the user asking them to move their wrists in
different directions.

Refer to the [compass example]({{site.links.examples_org}}/feature-compass) for
an example of how to implement this screen.

Calibration only runs while at least one app is subscribed to the compass
service. If all apps unsubscribe before calibration is complete, the calibration
is discarded and will start again from scratch the next time an app subscribes.
Once calibration succeeds, it is saved for future reuse by all apps without
recalibration. Putting the pebble on charge deletes any saved calibration.


## Magnetic North and True North

Depending on the user's location on Earth, the measured heading towards magnetic
north and true north can significantly differ. This is due to magnetic
variation, also known as 'declination'.

Pebble does not automatically correct the magnetic heading to return a true
heading, but the API is designed so that this feature can be added in the future
and the app will be able to automatically take advantage of it.

For a more precise heading, use the `magnetic_heading` field of
``CompassHeadingData`` and use a webservice to retrieve the declination at the
user's current location. Otherwise, use the `true_heading` field. This field
will contain the `magnetic_heading` if declination is not available, or the true
heading if declination is available. The field `is_declination_valid` will be
true when declination is available. Use this information to tell the user
whether the app is showing magnetic north or true north.

![Declination illustrated](/images/guides/pebble-apps/sensors/declination.gif)

> To see the true extent of declination, see how declination has
> [changed over time](http://maps.ngdc.noaa.gov/viewers/historical_declination/).


## Battery Considerations

Using the compass will turn on both Pebble's magnetometer and accelerometer.
Those two devices will have a slight impact on battery life. A much more
significant battery impact will be caused by redrawing the screen too often or
performing CPU-intensive work every time the compass heading is updated.

Use ``compass_service_subscribe()`` if the app only needs to update its UI when
new compass data is available, or else use ``compass_service_peek()`` if this
happens much less frequently.


## Defining "Up" on Pebble

Compass readings are always relative to the current orientation of Pebble. Using
the accelerometer, the compass service figures out which direction the user is
facing.

![Compass Orientation](/images/guides/pebble-apps/sensors/compass-orientation.png)

The best orientation to encourage users to adopt while using a compass-enabled
watchapp is with the top of the watch parallel to the ground. If the watch is
raised so that the screen is facing the user, the plane will now be
perpedicular to the screen, but still parallel to the ground.


## Angles and Degrees 

The magnetic heading value is presented as a number between 0 and 
TRIG_MAX_ANGLE (65536). This range is used to give a higher level of 
precision for drawing commands, which is preferable to using only 360 degrees. 

If you imagine an analogue clock face on your Pebble, the magnetic heading is
the position of magnetic North on that face, measured clockwise from the 12
o'clock position. For example, if North is at 3 o'clock the value is 90
degrees, and if North is at 9 o'clock it is 270 degrees. This makes it easy to
draw a needle pointing North: rotate it clockwise by `magnetic_heading`.

As a result, the value increases as you turn the watch counter clockwise, which
is the opposite of a compass bearing. To get the direction the top of the watch
is facing, measured clockwise from North as on a compass, subtract the value
from ``TRIG_MAX_ANGLE``:

```c
int bearing = TRIG_MAX_ANGLE - heading_data.magnetic_heading;
```

For example, with the top of the watch facing East, North is at 9 o'clock, so
`magnetic_heading` is 270 degrees and `bearing` is 90 degrees.

You can convert either value to degrees using the helper function
``TRIGANGLE_TO_DEG()``:

```c
int degrees = TRIGANGLE_TO_DEG(TRIG_MAX_ANGLE - heading_data.magnetic_heading);
```


## Subscribing to Compass Data

Compass heading events can be received in a watchapp by subscribing to the
``CompassService``:

```c
// Subscribe to compass heading updates
compass_service_subscribe(compass_heading_handler);
```

The provided ``CompassHeadingHandler`` function (called
`compass_heading_handler` above) can be used to read the state of the compass,
and the current heading if it is available. This value is given in the range of
`0` to ``TRIG_MAX_ANGLE`` to preserve precision, and so it can be converted
using the ``TRIGANGLE_TO_DEG()`` macro:

```c
static void compass_heading_handler(CompassHeadingData heading_data) {
  // Is the compass calibrated?
  switch(heading_data.compass_status) {
    case CompassStatusDataInvalid:
      APP_LOG(APP_LOG_LEVEL_INFO, "Not yet calibrated.");
      break;
    case CompassStatusCalibrating:
      APP_LOG(APP_LOG_LEVEL_INFO, "Calibration in progress. Heading is %ld",
                TRIGANGLE_TO_DEG(TRIG_MAX_ANGLE - heading_data.magnetic_heading));
      break;
    case CompassStatusCalibrated:
      APP_LOG(APP_LOG_LEVEL_INFO, "Calibrated! Heading is %ld",
                TRIGANGLE_TO_DEG(TRIG_MAX_ANGLE - heading_data.magnetic_heading));
      break;
  }
}
```

By default, the callback will be triggered whenever the heading changes by one
degree. To reduce the frequency of updates, change the threshold for heading
changes by setting a heading filter:

```c
// Only notify me when the heading has changed by more than 5 degrees.
compass_service_set_heading_filter(DEG_TO_TRIGANGLE(5));
```


## Unsubscribing From Compass Data

When the app is done using the compass, stop receiving callbacks by
unsubscribing:

```c
compass_service_unsubscribe();
```


## Peeking at Compass Data

To fetch a compass heading, simply peek to get a single sample:

```c
// Peek to get data
CompassHeadingData data;
compass_service_peek(&data);
```

If not already subscribed, this temporarily subscribes the app to the compass
service without a handler.

WARNING: Regardless of if you were already subscribed with a handler or not,
calling `compass_service_peek()` sets a timer to unsubscribe after 11 seconds
(refreshed on each call).

> Similar to the subscription-provided data, the app should examine the peeked
> ``CompassHeadingData`` to determine if it is valid (i.e. the compass is
> calibrated). Note that as calibration requires an active subscription, and
> calibration can take longer than 11 seconds, to calibrate while only using
> peek you must keep calling `compass_service_peek()` over time to refresh its
> unsubscribe timer until calibration is successful.
