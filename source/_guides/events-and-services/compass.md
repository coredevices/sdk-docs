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

If you imagine an analogue clock face on your Pebble, the angle 0 is always at 
the 12 o'clock position, and the magnetic heading angle is calculated in a 
counter clockwise direction from 0.

This can be confusing to grasp at first, as it’s opposite of how direction is 
measured on a compass, but it's simple to convert the values into a clockwise 
direction:

```c
int clockwise_angle = TRIG_MAX_ANGLE - heading_data.magnetic_heading;
```

Once you have an angle relative to North, you can convert that to degrees using 
the helper function `TRIGANGLE_TO_DEG()`:

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

To fetch a compass heading without subscribing, simply peek to get a single
sample:

```c
// Peek to get data
CompassHeadingData data;
compass_service_peek(&data);
```

> Similar to the subscription-provided data, the app should examine the peeked
> `CompassHeadingData` to determine if it is valid (i.e. the compass is
> calibrated).
