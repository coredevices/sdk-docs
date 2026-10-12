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
layout: mobile-app
title: Mobile App
description: |
  What the Pebble mobile app does for developers, where its source is, and
  how to build it and send changes to it.
permalink: /mobile-app/
generate_toc: true
search_index: true
search_group: Mobile App
---

The Pebble mobile app is the phone app for Pebble watches and the Index 01
ring. It runs on iOS and Android and is available at
[repebble.com/app](https://repebble.com/app). The app is open source at
[github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp),
written in Kotlin Multiplatform with one codebase for both platforms.
Developers can build their own features and open a pull request to the
repository, or maintain their own fork.

For app developers, the mobile app is the other half of a watchapp. It runs
the PebbleKit JS part of an app, carries the
{% guide_link tools-and-resources/developer-connection "Developer Connection" %}
that the `pebble` tool uses to install and debug apps on a watch, sideloads
`.pbw` files, and talks to the Pebble appstore. For Index 01 it collects
recordings from the ring, sends them to [webhooks](/index-01/webhooks/),
connects to [MCP servers](/index-01/mcp/) and runs
{% guide_link plugins "plugins" %}.


## Building the App

The repository
[README](https://github.com/coredevices/mobileapp#readme) has the setup
steps. On Android the app builds with Gradle from Android Studio and needs a
`google-services.json` in `androidApp/src`; a dummy file is provided. On
iOS the build needs Java 17, CocoaPods, an Android SDK (several modules use
the Android Gradle plugin) and the iOS platform for Xcode, after which
`./gradlew podInstall` sets up the dependencies and the app is built from
`iosApp/iosApp.xcworkspace` in Xcode. Features such as bug reporting, Google
sign-in and online transcription need tokens in `gradle.properties`; the
core features work without them.

The app can connect to a PebbleOS emulator over TCP in place of a watch.
{% guide_link tools-and-resources/testing-with-the-mobile-app %} covers
running the app against the emulator, which is how a change that touches
both the firmware and the app is tested.


## Related

* {% guide_link communication/using-pebblekit-js "PebbleKit JS" %} has a
  section on the differences between the PebbleKit JS runtime in the Pebble
  mobile app and the original one.
* {% guide_link tools-and-resources/developer-connection %} describes how
  the `pebble` tool installs apps through the phone.
* {% guide_link plugins %} describes the `.pbw` packages that run inside
  the app and extend the Index agent.
* [Index 01 webhooks](/index-01/webhooks/) describes the HTTP request the
  app sends for each recording.
* [Contributing](/mobile-app/contributing/) describes how changes get into
  the repository.
