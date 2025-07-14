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

title: Events and Services
description: |
  How to get data from the onboard sensors including the accelerometer, compass,
  and microphone.
guide_group: events-and-services
menu: false
permalink: /guides/events-and-services/
generate_toc: false
hide_comments: true
---

All Pebble watches contain a collection of sensors than can be used as input
devices for apps. Available sensors include four buttons, an accelerometer, and
a magnetometer (accessible via the ``CompassService`` API). In addition, the
Basalt and Chalk platforms also include a microphone (accessible via the
``Dictation`` API) and access to Pebble Health data sets. Read 
{% guide_link tools-and-resources/hardware-information %} for more information
on sensor availability per platform.

While providing more interactivity, excessive regular use of these sensors will
stop the watch's CPU from sleeping and result in faster battery drain, so use
them sparingly. An alternative to constantly reading accelerometer data is to
obtain data in batches, allowing sleeping periods in between. Read 
{% guide_link best-practices/conserving-battery-life %} for more information.


## Contents

{% include guides/contents-group.md group=page.group_data %}
