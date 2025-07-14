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

title: Event Services
description: |
  How to use the various asynchronous event services to power app features.
guide_group: events-and-services
order: 5
related_docs:
  - TickTimerService
  - ConnectionService
  - AccelerometerService
  - BatteryStateService
  - HealthService
  - AppFocusService
  - CompassService
---

All Pebble apps are executed in three phases, which are summarized below:

* Initialization - all code from the beginning of `main()` is run to set up all
  the components of the app.

* Event Loop - the app waits for and responds to any event services it has
  subscribed to.

* Deinitialization - when the app is exiting (i.e.: the user has pressed Back
  from the last ``Window`` in the stack) ``app_event_loop()`` returns, and all
  deinitialization code is run before the app exits.

Once ``app_event_loop()`` is called, execution of `main()` pauses and all
further activities are performed when events from various ``Event Service``
types occur. This continues until the app is exiting, and is typically handled
in the following pattern:

```c
static void init() {
  // Initialization code here
}

static void deinit() {
  // Deinitialization code here
}

int main(void) {
  init();
  app_event_loop();
  deinit();
}
```


## Types of Events

There are multiple types of events an app can receive from various event
services. These are described in the table below, along with their handler
signature and a brief description of what they do:

| Event Service | Handler(s) | Description |
|---------------|------------|-------------|
| ``TickTimerService`` | ``TickHandler`` | Most useful for watchfaces. Allows apps to be notified when a second, minute, hour, day, month or year ticks by. |
| ``ConnectionService`` | ``ConnectionHandler`` | Allows apps to know when the Bluetooth connection with the phone connects and disconnects. |
| ``AccelerometerService`` | ``AccelDataHandler``<br/>``AccelTapHandler`` | Allows apps to receive raw data or tap events from the onboard accelerometer. |
| ``BatteryStateService`` | ``BatteryStateHandler`` | Allows apps to read the state of the battery, as well as whether the watch is plugged in and charging. |
| ``HealthService`` | ``HealthEventHandler`` | Allows apps to be notified to changes in various ``HealthMetric`` values as the user performs physical activities. |
| ``AppFocusService`` | ``AppFocusHandler`` | Allows apps to know when they are obscured by another window, such as when a notification modal appears. |
| ``CompassService`` | ``CompassHeadingHandler`` | Allows apps to read a compass heading, including calibration status of the sensor. |

In addition, many other APIs also operate through the use of various callbacks
including ``MenuLayer``, ``AppMessage``, ``Timer``, and ``Wakeup``, but these
are not considered to be 'event services' in the same sense.


## Using Event Services

The event services described in this guide are all used in the same manner - the
app subscribes an implementation of one or more handlers, and is notified by the
system when an event of that type occurs. In addition, most also include a
'peek' style API to read a single data item or status value on demand. This can
be useful to determine the initial service state when a watchapp starts. Apps
can subscribe to as many of these services as they require, and can also
unsubscribe at any time to stop receiving events.

Each event service is briefly discussed below with multiple snippets - handler
implementation example, subscribing to the service, and any 'peek' API.


### Tick Timer Service

The ``TickTimerService`` allows an app to be notified when different units of
time change. This is decided based upon the ``TimeUnits`` value specified when a
subscription is added.

The [`struct tm`](http://www.cplusplus.com/reference/ctime/tm/) pointer provided
in the handler is a standard C object that contains many data fields describing
the current time. This can be used with
[`strftime()`](http://www.cplusplus.com/reference/ctime/strftime/) to obtain a
human-readable string.

```c
static void tick_handler(struct tm *tick_time, TimeUnits changed) {
  static char s_buffer[8];

  // Read time into a string buffer
  strftime(s_buffer, sizeof(s_buffer), "%H:%M", tick_time);

  APP_LOG(APP_LOG_LEVEL_INFO, "Time is now %s", s_buffer);
}
```

```c
// Get updates when the current minute changes
tick_timer_service_subscribe(MINUTE_UNIT, tick_handler);
```

> The ``TickTimerService`` has no 'peek' API, but a similar effect can be
> achieved using the ``time()`` and ``localtime()`` APIs.


### Connection Service

The ``ConnectionService`` uses a handler for each of two connection types:

* `pebble_app_connection_handler` - the connection to the Pebble app on the
  phone, analogous with the bluetooth connection state.

* `pebblekit_connection_handler` - the connection to an iOS companion app, if
  applicable. Will never occur on Android.

Either one is optional, but at least one must be specified for a valid
subscription.

```c
static void app_connection_handler(bool connected) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Pebble app %sconnected", connected ? "" : "dis");
}

static void kit_connection_handler(bool connected) {
  APP_LOG(APP_LOG_LEVEL_INFO, "PebbleKit %sconnected", connected ? "" : "dis"); 
}
```

```c
connection_service_subscribe((ConnectionHandlers) {
  .pebble_app_connection_handler = app_connection_handler,
  .pebblekit_connection_handler = kit_connection_handler
});
```

```c
// Peek at either the Pebble app or PebbleKit connections
bool app_connection = connection_service_peek_pebble_app_connection();
bool kit_connection = connection_service_peek_pebblekit_connection();
```


### Accelerometer Service

The ``AccelerometerService`` can be used in two modes - tap events and raw data
events. ``AccelTapHandler`` and ``AccelDataHandler`` are used for each of these
respective use cases. See the 
{% guide_link events-and-services/accelerometer %} guide for more
information.

**Data Events**

```c
static void accel_data_handler(AccelData *data, uint32_t num_samples) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Got %d new samples", (int)num_samples);
}
```

```c
const int num_samples = 10;

// Subscribe to data events
accel_data_service_subscribe(num_samples, accel_data_handler);
```

```c
// Peek at the last reading
AccelData data;
accel_service_peek(&data);
```

**Tap Events**

```c
static void accel_tap_handler(AccelAxisType axis, int32_t direction) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Tap event received");
}
```

```c
// Subscribe to tap events
accel_tap_service_subscribe(accel_tap_handler);
```


### Battery State Service

The ``BatteryStateService`` allows apps to examine the state of the battery, and
whether or not is is plugged in and charging.

```c
static void battery_state_handler(BatteryChargeState charge) {
  // Report the current charge percentage
  APP_LOG(APP_LOG_LEVEL_INFO, "Battery charge is %d%%", 
                                                    (int)charge.charge_percent);
}
```

```c
// Get battery state updates
battery_state_service_subscribe(battery_state_handler);
```

```c
// Peek at the current battery state
BatteryChargeState state = battery_state_service_peek();
```


### Health Service

The ``HealthService`` uses the ``HealthEventHandler`` to notify a subscribed app
when new data pertaining to a ``HealthMetric`` is available. See the 
{% guide_link events-and-services/health %} guide for more information.

```c
static void health_handler(HealthEventType event, void *context) {
  if(event == HealthEventMovementUpdate) {
    APP_LOG(APP_LOG_LEVEL_INFO, "New health movement event");
  }
}
```

```c
// Subscribe to health-related events
health_service_events_subscribe(health_handler, NULL);
```


### App Focus Service

The ``AppFocusService`` operates in two modes - basic and complete. 

**Basic Subscription**

A basic subscription involves only one handler which will be fired when the app
is moved in or out of focus, and any animated transition has completed.

```c
static void focus_handler(bool in_focus) {
  APP_LOG(APP_LOG_LEVEL_INFO, "App is %s in focus", in_focus ? "now" : "not");
}
```

```c
// Add a basic subscription
app_focus_service_subscribe(focus_handler);
```

**Complete Subscription**

A complete subscription will notify the app with more detail about changes in
focus using two handlers in an ``AppFocusHandlers`` object:

* `.will_focus` - represents a change in focus that is *about* to occur, such as
  the start of a transition animation to or from a modal window. `will_focus`
  will be `true` if the app will be in focus at the end of the transition.

* `.did_focus` - represents the end of a transition. `did_focus` will be `true`
  if the app is now completely in focus and the animation has finished.

```c
void will_focus_handler(bool will_focus) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Will %s focus", will_focus ? "gain" : "lose");
}

void did_focus_handler(bool did_focus) {
  APP_LOG(APP_LOG_LEVEL_INFO, "%s focus", did_focus ? "Gained" : "Lost");
}
```

```c
// Subscribe to both types of events
app_focus_service_subscribe_handlers((AppFocusHandlers) {
  .will_focus = will_focus_handler,
  .did_focus = did_focus_handler
});
```


### Compass Service

The ``CompassService`` provides access to regular updates about the watch's
magnetic compass heading, if it is calibrated. See the
{% guide_link events-and-services/compass %} guide for more information.

```c
static void compass_heading_handler(CompassHeadingData heading_data) {
  // Is the compass calibrated?
  if(heading_data.compass_status == CompassStatusCalibrated) {
    APP_LOG(APP_LOG_LEVEL_INFO, "Calibrated! Heading is %ld",
                             TRIGANGLE_TO_DEG(heading_data.magnetic_heading));
  }
}
```

```c
// Subscribe to compass heading updates
compass_service_subscribe(compass_heading_handler);
```

```c
// Peek the compass heading data
CompassHeadingData data;
compass_service_peek(&data);
```
