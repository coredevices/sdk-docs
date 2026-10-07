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

title: Appstore Publishing
description: |
  How to publish an app in the Pebble appstore from the Developer Dashboard,
  the `pebble` tool or CloudPebble.
guide_group: appstore-publishing
menu: false
permalink: /guides/appstore-publishing/
generate_toc: false
hide_comments: true
---

When an app is feature-complete and stable, the compiled `.pbw` file can be
uploaded to the Pebble appstore so that users can find and install it from the
Pebble mobile app. Listings are managed in the
[Developer Dashboard]({{ site.links.devportal }}). The `pebble` tool and
CloudPebble can also upload apps and new releases directly.

To be listed in the Pebble appstore an app must:

* Be built with a released SDK.

* Use a UUID that is not already in use by another app in the appstore.

* Have a title and a description, and a category if it is a watchapp.

* Comply with the [legal agreements](/legal/).

Apps that were published in the Rebble appstore can be imported into the
Developer Dashboard so that the same developer keeps managing them.


## Contents

{% include guides/contents-group.md group=page.group_data %}
