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

title: Wakeups
description: |
  Using the Wakeup API to launch an app at some future time.
guide_group: events-and-services
order: 8
related_examples:
  - title: Tea Timer
    url: https://github.com/pebble-examples/feature-app-wakeup
related_docs:
  - Wakeup
  - AppLaunchReason
  - launch_reason
  - Timer
---

The ``Wakeup`` API allows developers to schedule an app launch in the future,
even if the app itself is closed in the meantime. A wakeup event is scheduled in
a similar manner to a ``Timer`` with a future timestamp calculated beforehand.


## Calculating Timestamps

To schedule a wakeup event, first determine the timestamp of the desired wakeup
time as a `time_t` variable. Most uses of the ``Wakeup`` API will fall into
three distinct scenarios discussed below.


### A Future Time

Call ``time()`` and add the offset, measured in seconds. For example, for 30
minutes in the future:

```c
// 30 minutes from now
time_t timestamp = time(NULL) + (30 * SECONDS_PER_MINUTE);
```


### A Specific Time

Use ``clock_to_timestamp()`` to obtain a `time_t` timestamp by specifying a day
of the week and hours and minutes (in 24 hour format). For example, for the next
occuring Monday at 5 PM:

```c
// Next occuring monday at 17:00 
time_t timestamp = clock_to_timestamp(MONDAY, 17, 0);
```


### Using a Timestamp Provided by a Web Service

The timestamp will need to be translated using the 
[`getTimezoneOffset()`](http://www.w3schools.com/jsref/jsref_gettimezoneoffset.asp) 
method available in PebbleKit JS or with any timezone information given by the
web service.


## Scheduling a Wakeup

Once a `time_t` timestamp has been calculated, the wakeup event can be
scheduled:

```c
// Let the timestamp be 30 minutes from now
const time_t future_timestamp = time() + (30 * SECONDS_PER_MINUTE);

// Choose a 'cookie' value representing the reason for the wakeup
const int cookie = 0;

// If true, the user will be notified if they missed the wakeup 
// (i.e. their watch was off)
const bool notify_if_missed = true;

// Schedule wakeup event
WakeupId id = wakeup_schedule(future_timestamp, cookie, notify_if_missed);

// Check the scheduling was successful
if(id >= 0) {
  // Persist the ID so that a future launch can query it
  const wakeup_id_key = 43;
  persist_write_int(wakeup_id_key, id);
}
```

After scheduling a wakeup event it is possible to perform some interaction with
it. For example, reading the timestamp for when the event will occur using the
``WakeupId`` with ``wakeup_query()``, and then perform simple arithmetic to get
the time remaining:

```c
// This will be set by wakeup_query()
time_t wakeup_timestamp = 0;

// Is the wakeup still scheduled?
if(wakeup_query(id, &wakeup_timestamp)) {
  // Get the time remaining
  int seconds_remaining = wakeup_timestamp - time(NULL);
  APP_LOG(APP_LOG_LEVEL_INFO, "%d seconds until wakeup", seconds_remaining);
}
```

To cancel a scheduled event, use the ``WakeupId`` obtained when it was
scheduled:

```c
// Cancel a wakeup
wakeup_cancel(id);
```

To cancel all scheduled wakeup events:

```c
// Cancel all wakeups
wakeup_cancel_all();
```


## Limitations

There are three limitations that should be taken into account when using 
the Wakeup API:

* There can be no more than 8 scheduled wakeup events per app at any one time.

* Wakeup events cannot be scheduled within 30 seconds of the current time.

* Wakeup events are given a one minute window either side of the wakeup time. In
  this time no app may schedule an event. The return ``StatusCode`` of
  ``wakeup_schedule()`` should be checked to determine whether the scheduling of
  the new event should be reattempted. A negative value indicates that the
  wakeup could not be scheduled successfully.

The possible ``StatusCode`` values are detailed below:

|StatusCode|Value|Description|
|----------|-----|-----------|
| `E_RANGE` | `-8` | The wakeup event cannot be scheduled due to another event in that period. |
| `E_INVALID_ARGUMENT` | `-4` | The time requested is in the past. |
| `E_OUT_OF_RESOURCES` | `-7` | The application has already scheduled all 8 wakeup events. |
| `E_INTERNAL` | `-3` | A system error occurred during scheduling. |


## Handling Wakeup Events

A wakeup event can occur at two different times - when the app is closed, and
when it is already launched and in the foreground.

If the app is launched due to a previously scheduled wakeup event, check the
``AppLaunchReason`` and load the app accordingly:

```c
static void init() {
  if(launch_reason() == APP_LAUNCH_WAKEUP) {
    // The app was started by a wakeup event.
    WakeupId id = 0;
    int32_t reason = 0;

    // Get details and handle the event appropriately
    wakeup_get_launch_event(&id, &reason);
  }

  /* other init code */

}
```

If the app is expecting a wakeup to occur while it is open, use a subscription
to the wakeup service to be notified of such events:

```c
static void wakeup_handler(WakeupId id, int32_t reason) {
  // A wakeup event has occurred while the app was already open
}
```

```c
// Subscribe to wakeup service
wakeup_service_subscribe(wakeup_handler);
```

The two approaches can also be combined for a unified response to being woken
up, not depenent on the state of the app:

```c
// Get details of the wakeup
wakeup_get_launch_event(&id, &reason);

// Manually handle using the handler
wakeup_handler(id, reason);
```
