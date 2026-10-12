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

title: Subscriptions and Tokens
description: |
  The PebbleKit JS timeline subscription and token APIs, and what to use
  instead.
guide_group: pebble-timeline
order: 2
---

> Note: The timeline web API is no longer available. The Pebble mobile app
> does not sync pins from a server, and `Pebble.timelineSubscribe()`,
> `Pebble.timelineUnsubscribe()` and `Pebble.timelineSubscriptions()` do not
> work. Use
> {% guide_link pebble-timeline/timeline-local-pins "local pins" %}
> instead.

`Pebble.getTimelineToken()` still returns a token: the appstore token for an
installed app, or a placeholder for a sideloaded app while the *Emulate
Timeline Webservice* setting is on (the default). The token cannot be used to
push pins, since there is no server to push them to. See
{% guide_link communication/using-pebblekit-js#account-token "Using PebbleKit JS" %}
for the tokens that identify a user or a watch.

Apps add pins from PebbleKit JS with `Pebble.insertTimelinePin()` and remove
them with `Pebble.deleteTimelinePin()`. See
{% guide_link pebble-timeline/timeline-local-pins "Local Pins" %} for the API
and {% guide_link pebble-timeline/pin-structure "Creating Pins" %} for the pin
format.
