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

title: Announcing Pebble SDK 4.0
author: jonb
tags:
- Freshly Baked
---

Today we have the pleasure of announcing the release of Pebble SDK 4.0. We have
published an updated version of the Pebble Tool, the SDK itself, and we've
deployed 4.0 onto [CloudPebble]({{ site.links.cloudpebble }}). It's time to get
busy!



## What's New

Pebble OS 4.0 has been released and users with Pebble Time, Pebble Time Steel
and Pebble Time Round will be receiving the update today.

We covered the new features in detail
[very recently](/blog/2016/08/19/prime-time-is-approaching-for-os-4.0/), but
let's have a quick reminder of the new APIs and functionality that's included.

### Rocky.js

Javascript on the freakin' watch! Although still in beta,
[Rocky.js](/docs/rockyjs/) lets you start developing watchfaces in JavaScript
using standard Web APIs, which you can then run directly on your watch. It's an
embedded JavaScript revolution!

Read the updated
[Rocky.js blog post](/blog/2016/08/15/introducing-rockyjs-watchfaces/)
to get started.

### Timeline Quick View

Timeline Quick View displays upcoming information from your timeline on your
watchface. We introduced the ``UnobstructedArea`` API to allow developers to
detect if the screen is being obstructed by a system modal, such as Timeline
Quick View. Developers can use this new API to adapt their watchface layout
according to the available screen real estate.

Read the {% guide_link user-interfaces/unobstructed-area "UnobstructedArea guide" %}
to get started.

### AppGlances

With the new ``AppGlance`` API, developers can dynamically change the icon and
subtitle of their watchapp within the system launcher, at runtime. This allows
developers to provide meaningful feedback to users without the need for their
application to be launched.

Read the
{% guide_link user-interfaces/appglance-c "AppGlance C guide" %} and the
{% guide_link user-interfaces/appglance-pebblekit-js "AppGlance PebbleKit JS guide" %}
to get started.

### Diorite Platform

The new Pebble 2 devices use apps built for the Diorite platform, so you'll need
SDK 4.0 to develop applications which target those devices.

Take a look at the
{% guide_link tools-and-resources/hardware-information "Hardware Information guide" %}
to find out about the capabilities of the Pebble 2.

### One Click Action application

The One Click Action application pattern promotes a type of watchapp which
serves a single purpose. It launches, performs an action, and then terminates.
This pattern utilizes the new ``AppGlance`` and ``AppExitReason`` APIs.

Take a look at the
{% guide_link design-and-interaction/one-click-actions "One Click Actions guide" %}
to get started.

## Dude, Where's my HRM API?

We had planned on shipping the Heart Rate API with 4.0, but it's been pushed
back into 4.1 so that we can add even more awesomeness. Pebble 2 devices will
begin to appear on wrists after firmware 4.1 ships, so you'll still have time to
begin implementing HRM data into your watchapps and watchfaces. We will announce
details of the HRM API as soon as it's available.

## What's Next

Please remember that we will promote watchfaces and watchapps that make use of
these new 4.0 APIs if you submit them to the appstore **from August 31st
onwards**.

Let us know on [Twitter]({{ site.links.twitter }}) if you build something
cool using the new APIs! We'd love to hear about your experiences with the SDK.

Happy Hacking!

Team Pebble
