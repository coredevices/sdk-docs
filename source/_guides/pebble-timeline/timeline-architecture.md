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

title: Service Architecture
description: |
  Find out what the timeline is, how it works and how developers can take
  advantage of it in their apps.
guide_group: pebble-timeline
order: 4
---

> Note: The timeline web API is no longer available. The Pebble mobile app
> does not sync pins from a server. Use
> {% guide_link pebble-timeline/timeline-local-pins "local pins" %}
> instead.

Every item on the timeline is called a 'pin'. A pin can have information
attached to it which is used to show it to the user, such as layout, title,
start time and actions. When the user is viewing their timeline, they can use
the information provided about the immediate past and future to make decisions
about how they plan the rest of their day and how to respond to any missed
notifications or events.

The system and the Pebble mobile app populate the user's timeline with items
such as calendar appointments, missed calls and weather. Apps add their own pins
from PebbleKit JS. For example, a sports app could show a pin representing an
upcoming match so the user can see how long remains until it starts.

Pins are created on the phone and sent to the watch. There is no server in the
path, so no timeline token, API key or appstore listing is needed. The pin
format is described in {% guide_link pebble-timeline/pin-structure %} and the
PebbleKit JS API in {% guide_link pebble-timeline/timeline-local-pins %}.


## Architecture Overview

![diagram](/images/guides/3.0/timeline-architecture.png)

The diagram shows the original timeline service. The 'Pebble Timeline API'
cloud service and the developer's server no longer exist; today pins travel
only between the phone and the watch.


### Watch Timeline

The watch stores the pins and shows them when the user presses Up for the past
or Down for the future from the watchface. Alarm pins are inserted directly on
the watch. Pins carry their own layout, reminders and actions, so the watch does
not need to contact the phone to display them.


### Pebble Mobile App

The Pebble mobile app inserts system pins for the user's upcoming calendar
events, missed calls and weather, and syncs them to the watch. It also runs the
PebbleKit JS component of each installed app and forwards the pins that
component inserts.


## Sources of Pins

### System Pins

Calendar, missed call and weather pins are created by the Pebble mobile app.
Alarm pins are created by the watch. Apps cannot change these pins.


### Local Pins

Apps insert pins from PebbleKit JS with `Pebble.insertTimelinePin()` and remove
them with `Pebble.deleteTimelinePin()`. Each pin is created on the phone that
runs the app's JavaScript, so pins are not shared with the user's other phones
and are only inserted while the app's JavaScript is running. Developers can use
PebbleKit JS to combine the user's preferences from a configuration page
(detailed in {% guide_link user-interfaces/app-configuration %}) with their
location and data from web services to decide which pins to insert.
