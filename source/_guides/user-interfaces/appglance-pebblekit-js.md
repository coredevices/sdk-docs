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

title: AppGlance in PebbleKit JS
description: |
  How to update an app's glance using PebbleKit JS.
guide_group: user-interfaces
order: 2
related_docs:
  - AppGlanceSlice
---

> Note: `Pebble.appGlanceReload()` is not supported in the Pebble mobile app
> and its callbacks never fire. Use the
> {% guide_link user-interfaces/appglance-c "C AppGlance API" %} from the
> watchapp instead.

The {% guide_link user-interfaces/appglance-c %} guide describes how to set the
icon and subtitle shown alongside an app in the launcher with
``app_glance_reload()``, including the slice format, system and published
media icons, and the subtitle template string language.
