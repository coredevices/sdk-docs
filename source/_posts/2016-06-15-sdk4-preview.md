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

title: A Wild SDK Appears
author: cat
tags:
- Freshly Baked
---

Developers rejoice - we’ve released the first version of our [SDK 4](/sdk4)
developer preview! This SDK enables you to start building applications for the
new Diorite platform (Pebble 2), and includes a set of new APIs for interacting
with the 4.0 user experience.

In this blog post we’ll dive into the [App Glance](/docs/c/Foundation/App_Glance/),
[`UnobstructedArea`](/docs/c/User_Interface/UnobstructedArea/), and
[`AppExitReason`](/docs/c/Foundation/Exit_Reason/) APIs, and explain
how you can use them to create great experiences for your users!



## App Glance API

Let’s start with the App Glance API, which allows applications to present
information for the launcher to display. The information an application displays
in the launcher is called an app glance - and the information that is displayed
at any particular point in time is referred to as an [`AppGlanceSlice`](/docs/c/Foundation/App_Glance/#AppGlanceSlice).

![Virtual Pet App >{pebble-screenshot,pebble-screenshot--time-black}](/images/blog/2016-06-15-sdk4-preview/virtual-pet.png)

`AppGlanceSlice`s have expiration times, which means you can add multiple slices
at once. Slices will be displayed in the order they are added and removed at
their specified expiration times.

```c
static void prv_update_app_glance(AppGlanceReloadSession *session, size_t limit, void *context) {
  // This shouldn't happen, but developers should always ensure they have
  // sufficient slices, or adding slices may fail.
  if (limit < 1) return;

  // !! When layout.icon_resource_id is not set, the app's default icon is used
  const AppGlanceSlice entry = (AppGlanceSlice) {
    .layout = {
      .template_string = "Hello from the app glance"
    },
    .expiration_time = APP_GLANCE_SLICE_NO_EXPIRATION
  };

  // Add the slice, and store the result so we can check it later
  AppGlanceResult result = app_gpance_add_slice(session, entry);
}
```

To dig into this feature, we recommend you start with our new
[AppGlance C API guide](/guides/user-interfaces/appglance-c), and also give the
[API docs](/docs/c/Foundation/App_Glance/) a quick read.

> We are planning to extend the AppGlance API to include a PebbleKit JS API, as
> well as a HTTP web API, intended to allow developers to push `AppGlanceSlice`s
> from external web services to their users' smartwatches.

## UnobstructedArea API

The [`UnobstructedArea`](/docs/c/User_Interface/UnobstructedArea/) API
allows developers to create watchfaces capable of sensing, and responding to
Timeline Quick View events. Timeline Quick View is a new feature in SDK 4.0, 
which displays upcoming and ongoing events on top of the user’s watchface. The 
functionality added through the `UnobstructedArea` API allows developers to get 
the unobstructed bounds of a layer, or subscribe to events related to the
watchface’s unobstructed area changing.

```c
static int s_offset_top_percent = 33;
static int s_offset_bottom_percent = 20;

static void prv_unobstructed_change(AnimationProgress progress, void *context) {
  // Get the total available screen real-estate
  GRect bounds = layer_get_unobstructed_bounds(window_layer);

  // Shift the Y coordinate of the top text layer
  GRect top_frame = layer_get_frame(text_layer_get_layer(s_top_text_layer));
  top_frame.origin.y = bounds.size.h * s_offset_top_percent / 100;
  layer_set_frame(top_frame, text_layer_get_layer(s_top_text_layer));


  // Shift the Y coordinate of our bottom text layer
  GRect bottom_frame = layer_get_frame(text_layer_get_layer(s_bottom_text_layer));
  bottom_frame.origin.y = bounds.size.h * s_offset_bottom_percent / 100;
  layer_set_frame(bottom_frame, text_layer_get_layer(s_bottom_text_layer));
}

static void prv_main_window_load(Window *window) {
  unobstructed_area_service_subscribe((UnobstructedAreaHandlers) {
    .change = prv_unobstructed_change
  }, NULL);
}
```

> We encourage developers to begin exploring what their existing watchfaces will
> look like when the system is displaying the Timeline Quick View dialog, and
> adjust their designs to provide the best experience possible for users.

Take a look at our [UnobstructedArea API Guide](/guides/user-interfaces/unobstructed-area/)
and the [API documentation](/docs/c/User_Interface/UnobstructedArea/) to
get started!

## AppExitReason API

One of the APIs we haven’t talked about as much is the
[`AppExitReason`](/docs/c/Foundation/Exit_Reason/) API, which enables
developers to specify why their app exited, and determines whether the system
returns the user to the launcher, or the active watchface. Take a look at our
[AppExitReason API Guide](/guides/user-interfaces/app-exit-reason),
and read [the API docs](/docs/c/Foundation/Exit_Reason) to learn more.

This feature enables developers to create "One Click Action" watchapps, that
perform an action, then immediately return the user to the watchface to create a
simple, fluid experience.

![Uber App >{pebble-screenshot,pebble-screenshot--time-black}](/images/blog/2016-06-15-sdk4-preview/uber.gif)

To help get you started thinking about and designing One Click Action apps,
we’ve created a [One Click Action App Guide](/guides/design-and-interaction/one-click-actions)
around the relatively minimal example of locking and unlocking your front door
(with a [Lockitron lock](https://lockitron.com)).

## 4.0 Emulator

The SDK 4 preview also includes an update to the emulator, which not only adds
support for Pebble 2, but includes the updated 4.0 user interface, and a few
other goodies that we’re sure developers will love.

The new emulator includes a launcher capable of displaying watchapps’ glances,
and can be accessed by pressing the `Select` button from the watchface.

CloudPebble and the Pebble Tool also include new functionality to enable
developers to toggle Timeline Quick View, allowing you to make sure your
watchface looks good in every context!

Finally, we’ve added the ability to install multiple watchfaces and watchapps
into the emulator. Watchfaces and watchapps installed into the emulator will
remain installed (even if the emulator is closed) until `pebble wipe` is called
from the command line.

Due to limitations with CloudPebble, this feature is currently only available in
the Pebble Tool.

## What’s Next

The SDK 4 developer preview is exactly that, a preview. You’ve probably noticed
a few really important and exciting features we didn’t mention - the Heart Rate
API has been designed, but is not yet fully implemented, and we have not yet
added the ability to build applications for the Emery Platform (Pebble Time 2).

The official SDK 4 release is currently planned for the end of August - and it
will include not only the Heart Rate API, and support for building Emery
applications, but the first version of Pebble’s fantastic new embedded
JavaScript SDK, [Rocky.js](http://pebble.github.io/rockyjs/).

## Show Us What You Make

While we’ve been conceptualizing and designing the new functionality in SDK 4
for quite a long time, the API itself is relatively new, even for those of us
lucky enough to ‘be on the inside’ - so we’ve only really just begun to see
what’s possible, and we’re more than excited to see what you’ll build with this
new functionality.

Send us a link to something you’ve built on Twitter (
[@pebbledev](https://twitter.com/pebbledev)) and we’ll look at including it in
an upcoming newsletter (and send some swag your way).

Happy Hacking!

Team Pebble
