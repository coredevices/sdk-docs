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
title: PebbleKit JS in the Pebble Mobile App
description: |
  How the Pebble mobile app runs PebbleKit JS on Android and iOS, and the
  differences from the original Pebble apps that affect existing code.
guide_group: communication
order: 7
---

The Pebble mobile app runs PebbleKit JS differently on each phone platform.
On Android the JavaScript runs in a hidden WebView, so the full set of
browser APIs is available. On iOS it runs in JavaScriptCore with a small set
of APIs added by the app: `XMLHttpRequest`, `WebSocket`, `setTimeout` and
`setInterval`, `localStorage`, `atob` and `btoa`, `navigator.geolocation`,
and `console`. Anything else that a browser provides, such as `fetch`, `Blob`
or the DOM, does not exist on iOS.

Code that follows {% guide_link communication/using-pebblekit-js %} works
on both. This guide lists the behaviour that differs from the original Pebble
apps, or between Android and iOS, so that existing apps can be checked
against it. The source is at
[github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp).


## Lifecycle

The JavaScript for an app starts when the app starts running on the watch and
stops when the app exits. Launching the app again, or reconnecting the watch,
starts a fresh JavaScript context, so state that must survive belongs in
`localStorage`. Only one app's JavaScript runs at a time.

On iOS the `ready` event fires as soon as the app's script has been
evaluated. On Android it fires once the script has loaded in the WebView.
Messages from the watch that arrive before `ready` are held for up to six
seconds.

On iOS the phone suspends the Pebble mobile app when it is in the background
and no Bluetooth activity is pending. Timers do not fire while the app is
suspended and run late when it resumes, so do not rely on `setInterval` for
work that must happen while the user is not looking at the phone.


## Network Requests

Use `XMLHttpRequest`. It is the WebView's own implementation on Android and
the app's implementation on iOS, where these limits apply:

* Event handlers receive an event with only a `type` property. Read the result
  from the request object, not from `event.target`.

* `responseType` can be `""`, `"text"`, `"json"` or `"arraybuffer"`.
  `"blob"` and `"document"` throw. An `arraybuffer` response is delivered as
  a `Uint8Array`.

* There is no `timeout` property and there are no progress events.

* Synchronous requests (`async` set to `false` in `open()`) still deliver
  their response asynchronously, so the response is not available when
  `send()` returns. Always use asynchronous requests.

`fetch()` is only available on Android. Apps that use it fail on iOS with
`fetch is not defined`.

`WebSocket` is available on both platforms. On iOS `binaryType` is always
`"arraybuffer"`.


## Storage

`localStorage` is separate for each app, keyed by the app's UUID, and keeps
its contents across app launches and phone app restarts. Values are stored as
strings, as in a browser.

On Android, values written through the `localStorage` object are saved when
the app's JavaScript stops. Use `localStorage.setItem()` rather than
assigning properties so that writes are not lost if the phone app is killed.


## Geolocation

`navigator.geolocation.getCurrentPosition()` and `watchPosition()` work on
both platforms with these differences from a browser:

* `maximumAge` (default 0) and `timeout` (default 15 seconds) are honoured.
  When the timeout passes and a previous position is known, that position is
  returned instead of an error.

* `enableHighAccuracy` only affects `watchPosition()`.

* The position object has `coords` with `latitude`, `longitude`,
  `accuracy`, `altitude`, `heading` and `speed`, and no `timestamp`.

* Errors always have `code` set to `1` and a `message` string.


## Tokens

`Pebble.getAccountToken()` and `Pebble.getWatchToken()` are derived from
the signed-in Pebble account (or, for the watch token, the watch serial)
together with the developer ID of an appstore app or the UUID of a sideloaded
app. Both tokens therefore change when an app that was tested by sideloading
is installed from the appstore. Treat data stored against a token from a
sideloaded build as test data.

`Pebble.getTimelineToken()` returns the token the appstore issued for the
app. Sideloaded apps have none. The Pebble mobile app does not sync pins from
a server, so use {% guide_link pebble-timeline/timeline-local-pins "local pins" %}
instead of the timeline token.


## Watch Information

`Pebble.getActiveWatchInfo()` returns `platform`, `model`, `language` and
`firmware` (`major`, `minor`, `patch`, `suffix`). The `platform` value is
the connected watch's platform only when that platform is in the app's
`targetPlatforms`. When the watch is running a build for an older platform,
`platform` reports the platform of the build that is installed:

| Connected watch | Reported when not a target |
|-----------------|----------------------------|
| flint (Pebble 2 Duo) | diorite if targeted, otherwise aplite |
| emery (Pebble Time 2) | basalt |
| gabbro (Pebble Round 2) | chalk |

Add the new platforms to `targetPlatforms` and rebuild to receive their real
names.


## AppMessage

`Pebble.sendAppMessage()` follows these rules:

* Keys must be names declared in `messageKeys` in `package.json`, or numeric
  strings. Keys that are not declared are dropped without an error.

* Values can be strings, integers, booleans (sent as 0 or 1) and arrays of
  numbers (sent as a byte array). Fractional numbers are truncated to
  integers. Nested objects are not supported and stop the message from being
  sent.

* The call fails with `"Failed to connect to Pebble"` if the watch does not
  accept the message within five seconds. If the watch does not acknowledge
  the message within ten seconds, the failure callback receives an error of
  `"nack"`.


## Configuration Pages

`Pebble.openURL()` is only honoured in response to the `showConfiguration`
event, and must be called within ten seconds of it. The page opens in a
WebView inside the Pebble mobile app, not in the system browser. `data:` URLs
are accepted, so a configuration page can be embedded in the app's JavaScript.

The page returns its result by navigating to `pebblejs://close#<data>`.
`pebblejs://close/?<data>` and `pebblejs://close/<data>` are also accepted;
`pebblejs://close?data=...` is not. The data is percent-decoded once and
passed to the `webviewclosed` handler as `e.response`. It is not parsed, so
call `JSON.parse(e.response)` as before. If the page is closed without data,
or the user leaves it with the back button, `webviewclosed` does not fire.
Read {% guide_link user-interfaces/app-configuration %} for the full flow.


## Plugins (Preview)

The `Pebble` object has four functions for the plugins preview. They do
nothing useful until the preview is turned on in the Pebble mobile app, which
is off by default, and the API will change; read
{% guide_link communication/plugins %} before using them.

* `Pebble.enumeratePlugins()` returns an array of the installed plugins with
  their sources and actions.

* `Pebble.subscribeToSource(config)` subscribes to a category and item and
  delivers updates to `config.onData`.

* `Pebble.invokeAction(config)` runs one action on one plugin and returns a
  Promise that resolves with the result.

* `Pebble.sendConfigMessage(message)` pushes a message to the app's own
  settings page while it is open.


## Other Differences

* `Pebble.showToast()` shows a toast on Android and does nothing on iOS.

* `Pebble.getVersionCode()` is not available. Calling it throws.

* `Pebble.timelineSubscribe()`, `timelineUnsubscribe()`,
  `timelineSubscriptions()` and `appGlanceReload()` do nothing and never call
  back. Server-pushed pins and glances are not supported.

* `console.log()` output appears in `pebble logs` prefixed with the app's
  name and the line number. The Pebble mobile app's own log, the one
  included in bug reports, replaces lines containing words such as "token"
  or "location" with `<REDACTED>` when the setting that obfuscates log
  content is on; the Developer Connection log is not redacted.
