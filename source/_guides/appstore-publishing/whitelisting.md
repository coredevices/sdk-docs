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

title: iOS App Whitelisting
description: |
  Instructions to iOS developers to get their Pebble apps whitelisted.
guide_group: appstore-publishing
generate_toc: false
order: 4
---

Pebble is part of the Made For iPhone program, a requirement that hardware
accessories must meet to interact with iOS apps. If an iOS app uses PebbleKit
iOS, it must be whitelisted **before** it can be submitted to the Apple App
Store for approval.


## Requirements

* The iOS companion app must only start communication with a Pebble watch on
  an explicit action in the UI. It cannot auto­start upon connection and it must
  stop whenever the user stops using it. Refer to the
  {% guide_link communication/using-pebblekit-ios %} guide for details.

* `com.getpebble.public` is the only external accessory protocol that can be
  used by 3rd party apps. Make sure this is listed in the `Info.plist` in the
  `UISupportedExternalAccessoryProtocols` array.

* Pebble may request a build of the iOS application. If this happens, the
  developer will be supplied with UDIDs to add to the provisioning profile.
  TestFlight/HockeyApp is the recommended way to share builds with Pebble.

[Whitelist a New App >{center,bg-lightblue,fg-white}](http://pbl.io/whitelist)

After whitelisting of the new app has been confirmed, add the following
information to the "Review Notes" section of the app's Apple app submission:

<div style="text-align: center;">
  <strong>MFI PPID 126683­-0003</strong>
</div>

> Note: An iOS app does not need to be re-whitelisted every time a new update is
> released. However, Pebble reserves the right to remove an application from the
> whitelist if it appears that the app no longer meets these requirements.
