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

title: Hardware Information
description: |
  Details of the the capabilities of the various Pebble hardware platforms.
guide_group: tools-and-resources
order: 4
---

The Pebble watch family comprises of multiple generations of hardware, each with
unique sets of features and capabilities. Developers wishing to reach the
maximum number of users will want to account for these differences when
developing their apps.

The table below details the differences between hardware platforms:

{% include hardware-platforms.html %}

See
{% guide_link best-practices/building-for-every-pebble#available-defines-and-macros "Available Defines and Macros" %}
for a complete list of compile-time defines available.

## Platform Support

Each Pebble watch is identified by a platform name in the SDK:

| Platform | Watches |
|----------|---------|
| `aplite` | Pebble, Pebble Steel |
| `basalt` | Pebble Time, Pebble Time Steel |
| `chalk` | Pebble Time Round |
| `diorite` | Pebble 2 |
| `flint` | Pebble 2 Duo |
| `emery` | Pebble Time 2 |
| `gabbro` | Pebble Round 2 |

Not every language and feature is available on every platform:

| Feature | Platforms | Notes |
|---------|-----------|-------|
| C SDK | All | |
| Alloy (JavaScript on the watch) | `emery`, `gabbro` | The firmware includes the Alloy runtime on `emery` and `gabbro` only, and the `pebble` tool templates target those two. CloudPebble also lists `flint`, but Alloy apps do not run on `flint` yet. `aplite`, `basalt`, `chalk` and `diorite` are not supported. See {% guide_link alloy %}. |
| PebbleKit JS | All | Runs on the phone, in the Pebble mobile app. |
| Touch | `emery`, `gabbro` | Watchapps only. Watchfaces cannot receive touch events. See {% guide_link events-and-services/touch %}. |
| Heart rate monitor | `diorite` (except Pebble 2 SE), `emery` | See {% guide_link events-and-services/hrm %}. |
| Speaker | `flint`, `emery` | See {% guide_link events-and-services/speaker %}. |
| Microphone | All except `aplite` | See {% guide_link events-and-services/dictation %}. |

Watchfaces cannot receive button or touch events on any platform.
