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

title: Testing with the Pebble Mobile App
description: |
  How to connect the Pebble mobile app to the emulator to test PebbleKit JS,
  configuration pages and timeline pins without a watch, and how to sideload
  a .pbw file.
guide_group: tools-and-resources
order: 6
---

The `pebble` tool runs its own PebbleKit JS environment next to the emulator,
which is enough for most development. Some things only the Pebble mobile app
does: the phone-side settings screen that opens configuration pages, the
appstore locker, timeline pins created by PebbleKit JS and the real
JavaScript runtimes described in
{% guide_link communication/pebblekit-js-in-the-mobile-app %}. To test those
without a watch, the Pebble mobile app can connect to a PebbleOS emulator over
TCP in place of a Bluetooth watch.

This needs the PebbleOS emulator built from source, since the Pebble mobile app
connects to the emulator's Pebble Protocol port and only one client can use
that port at a time. The emulator started by `pebble install --emulator` is
already attached to the `pebble` tool's own PebbleKit JS runtime, so it cannot
be used.


## Running the PebbleOS Emulator

Follow the build instructions in the
[PebbleOS repository](https://github.com/coredevices/pebbleos) to build one of
the `qemu_emery`, `qemu_flint` or `qemu_gabbro` boards, then start it:

```text
$ pbl configure --board=qemu_emery
$ pbl build
$ pbl qemu
```

The emulator serves the Pebble Protocol on TCP port 12344 of the computer. The
`pebble` tool connects to this port with `--qemu`, so apps can still be
installed and their logs read from the command line while the phone is
connected:

```text
$ pebble install --qemu localhost:12344
$ pebble logs --qemu localhost:12344
```

> Note: Only one client can be attached to the emulator's port at a time. When
> the Pebble mobile app is connected, disconnect it before using `--qemu` from
> the `pebble` tool, or install apps from the phone instead.


## iOS Simulator

The iOS version of the Pebble mobile app accepts the emulator address as a
launch argument. This is only possible from `simctl` or Xcode, so it works in
the iOS Simulator and not on an iPhone. Build the app from the
[mobileapp repository](https://github.com/coredevices/mobileapp), install it
in a booted simulator and launch it with:

```text
$ xcrun simctl launch booted coredevices.coreapp -qemu 127.0.0.1:12344
```

The simulator runs on the same computer as the emulator, so `127.0.0.1` is
the emulator's address.


## Android

On Android the emulator can be reached from a device or an emulator image
connected with `adb`. Forward the emulator's port to the phone, then tell the
app to add the emulator as a watch:

```text
$ adb reverse tcp:12344 tcp:12344
$ adb shell am broadcast -a coredevices.coreapp.ADD_QEMU_WATCH \
    -n coredevices.coreapp/coredevices.coreapp.debug.QemuSetupReceiver \
    --es host 127.0.0.1 --ei port 12344
```

The broadcast is only accepted from `adb`; another app on the phone cannot
send it. After the broadcast the emulator appears in the *Devices* tab like a
watch, and the app connects to it.

### Faking a Location

Apps that use `navigator.geolocation` in PebbleKit JS need a location on the
phone. On an Android device without GPS reception, or an Android emulator
image, set a test location with `adb`. Repeat the last command periodically
so the fix does not go stale:

```text
$ adb shell appops set com.android.shell android:mock_location allow
$ for p in gps fused; do
    adb shell cmd location providers add-test-provider $p
    adb shell cmd location providers set-test-provider-enabled $p true
    adb shell cmd location providers set-test-provider-location $p \
        --location 37.4438,-122.1650
  done
```


## Sideloading Apps

Opening a `.pbw` file on the phone installs it on the connected watch. On
Android the Pebble mobile app registers for `.pbw`, `.pbl` and `.pbz` files,
so a file received by email, downloaded in the browser or shared from another
app opens in the Pebble mobile app. On iOS the app declares the same document
types, so a `.pbw` can be opened from the Files app, Mail, AirDrop or a share
sheet. The app is added to the locker with the version marked *(sideloaded)*,
and it is installed from there like an appstore app.

Sideloaded apps have no appstore listing, so `Pebble.getTimelineToken()`
returns nothing, and `Pebble.getAccountToken()` and `Pebble.getWatchToken()`
return different values from the ones the same app gets once it is published.
Read {% guide_link communication/pebblekit-js-in-the-mobile-app#tokens "Tokens" %}
for details.

The simplest way to get a `.pbw` onto a phone during development is still the
{% guide_link tools-and-resources/developer-connection %}, which installs the
build directly from the `pebble` tool or CloudPebble.
