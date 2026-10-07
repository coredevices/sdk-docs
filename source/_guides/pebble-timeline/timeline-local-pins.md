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

title: Local Pins
description: |
  How to insert pins into the timeline directly from PebbleKit JS, without a
  web server or timeline API keys.
guide_group: pebble-timeline
order: 5
---

PebbleKit JS can insert pins into the timeline directly from the phone. Local
pins are created by the new Pebble app and synced to the watch, which means:

* No timeline token, API key, or appstore listing is needed, so sideloaded apps
  can use them.
* Pins only exist on the phone that created them - they are not shared with the
  user's other phones, and cannot be created while your app's JS is not running.

> The new Pebble app does not support the
> {% guide_link pebble-timeline/timeline-public "timeline web API" %}, so pins
> can no longer be pushed to users from a web server. Local pins are the only
> way to add pins to the timeline.


## Inserting a Pin

Pass a pin object (or a JSON string) in the format described in
{% guide_link pebble-timeline/pin-structure "Creating Pins" %}:

```js
Pebble.insertTimelinePin({
  id: 'local-pin-1',
  time: new Date().toISOString(),
  layout: {
    type: 'genericPin',
    title: 'Local pin',
    tinyIcon: 'system://images/NOTIFICATION_FLAG'
  }
});
```

The `id` is chosen by you and only needs to be unique within your app.
Inserting a pin with an `id` that already exists updates that pin, rather than
creating a second one.


## Deleting a Pin

Pins are removed using the same `id` they were inserted with:

```js
Pebble.deleteTimelinePin('local-pin-1');
```


## Existing Timeline Web API Code

Apps written against the timeline web API do not need to be rewritten to keep
working. Requests made from PebbleKit JS to `timeline-api.rebble.io` or
`timeline-api.getpebble.com` under `/v1/user/pins` are intercepted by the phone
and turned into local pins instead of being sent to a server - a `PUT` or
`POST` inserts the pin in the request body, and a `DELETE` removes the pin
named in the URL. The request completes with a `200` response and an empty
body.

Only requests made by your app's JS are intercepted. Pins your backend pushes
to the timeline web API will never reach the watch.

> Interception can be turned off by the user with the 'Emulate Timeline
> Webservice' setting in the Pebble app, so new apps should call
> `Pebble.insertTimelinePin()` directly.


## Unsupported Fields

Local pins use the pin format described in
{% guide_link pebble-timeline/pin-structure "Creating Pins" %}, with the
following exceptions:

| Field | Behavior |
|-------|----------|
| `createNotification` | Ignored - no notification is shown when the pin is created. |
| `updateNotification` | Ignored - no notification is shown when the pin is updated. |
| `actions` | Ignored. Every local pin gets a 'Remove' action. |
| `primaryColor`, `secondaryColor`, `backgroundColor` | Ignored. |

All other fields, including `duration` and `reminders`, are supported.
