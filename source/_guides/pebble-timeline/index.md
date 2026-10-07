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

title: Pebble Timeline
description: |
  How to use Pebble timeline to bring timely information to app users outside
  the app itself.
guide_group: pebble-timeline
permalink: /guides/pebble-timeline/
generate_toc: false
menu: false
hide_comments: true
---

The Pebble timeline is a system-level display of chronological events that apps
can insert data into to deliver user-specific data, events, notifications and
reminders. These items are called pins and are accessible outside the running
app, but are deeply associated with an app the user has installed on their
watch.

Every user can view their personal list of pins from the main watchface by
pressing Up for the past and Down for the future. The Pebble mobile app inserts
pins for weather, calendar events and missed calls, and apps insert their own
pins, such as sports scores or news items, from PebbleKit JS.


## Contents

{% include guides/contents-group.md group=page.group_data %}


## Adding Pins

Apps add pins from PebbleKit JS with `Pebble.insertTimelinePin()` and remove
them with `Pebble.deleteTimelinePin()`. The Pebble mobile app creates the pin
and syncs it to the watch. No timeline token, API key or appstore listing is
needed, so sideloaded apps can add pins. See
{% guide_link pebble-timeline/timeline-local-pins "Local Pins" %} for the API
and {% guide_link pebble-timeline/pin-structure "Creating Pins" %} for the pin
format.

> Note: The timeline web API is no longer available. The Pebble mobile app
> does not sync pins from a server, and `Pebble.timelineSubscribe()`,
> `Pebble.timelineUnsubscribe()` and `Pebble.timelineSubscriptions()` do not
> work. Use
> {% guide_link pebble-timeline/timeline-local-pins "local pins" %}
> instead.
