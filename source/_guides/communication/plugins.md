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
title: Plugins (Preview)
description: |
  How a .pbw's JavaScript can provide data sources and actions to other apps
  through the Pebble mobile app, and how a watchapp reads them from PebbleKit
  JS. Preview: off by default and subject to change.
guide_group: communication
order: 8
---

{% alert important %}
Plugins are a preview. The API described here will change before plugins are
released to all users, and the Pebble mobile app ships with them turned off.
Do not publish apps that use or provide plugins to the appstore yet.
{% endalert %}

A plugin is JavaScript in a `.pbw` that runs on the phone, inside the Pebble
mobile app, and offers two things to other apps: *sources*, data that any
watchface or watchapp can read, and *actions*, operations such as turning a
light off or adding a task that any watchapp can trigger. The Pebble mobile
app also exposes some of its own data as built-in plugins: weather for the
user's saved locations, calendar events, phone state, watch settings and, on
Android, the current music track and notifications.

A watchface that shows the weather no longer needs its own weather API and
key. It subscribes to `weather/location` and whichever weather plugin the
user has installed answers. A developer with a data source of their own, such
as a blood sugar monitor or a bus timetable, can ship it as a plugin and the
user can show it on any watchface that reads that kind of data. The
implementation and the demo projects are at
[github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp),
under `libpebble3/.../plugin/` and `test-apps/`.


## Enabling the Preview

Plugins are off by default (`enablePlugins` in the app's watch configuration).
To turn them on in the Pebble mobile app, version 1.14.0 or later:

* Open *Settings* and, in the *Debug* section, turn on *Show debug options*.

* Turn on *Use experimental plugins*.

While the setting is on, the demo apps and plugins listed below are installed
into the locker automatically and a *Plugins* tab appears on the *Apps* screen
listing the installed plugins and their settings pages. Turning the setting
off removes the demo apps and stops every plugin.

> Note: The setting's own description says that plugins can expose private
> data until the permission system is finished. See
> [Permissions](#permissions).


## The Demo Apps

The source for each demo is in `test-apps/` of the mobile app repository.

| Project | Name in the locker | What it shows |
|---------|--------------------|---------------|
| `weather-face` | Plugin Demo: Weather Face | A watchface built entirely from the built-in weather plugin. |
| `plugin-test` | Plugin Demo: Dashboard | A watchapp with eight tiles, each set from its settings page to any reading from any installed plugin. Taps can trigger actions. |
| `stocks` | Stocks | A plugin-only `.pbw`: share prices for tickers chosen on its settings page. The smallest example to copy. |
| `hue` | Hue | Controls Philips Hue lights on the local bridge. Shows `LocalNetwork` and actions with `targets`. |
| `notion`, `ticktick`, `todoist` | Notion, TickTick, Todoist | Plugins that sign in with OAuth. |


## Concepts

### Sources

A source is addressed in layers. An app asks for a *category* and an *item*,
receives one or more *instances* of that item, and each instance carries
*properties*, each offered in one or more *shapes*:

```text
category   home
  item     room_lights          the kind of thing
    instance   "3"              one room; its name property is "Living room"
      property   brightness     one reading of it
        shape    numericValue   { value: 64, unit: "%", min: 0, max: 100 }
```

A subscription to an item delivers every property of every instance of it,
and delivers again when the data changes. Instances have a stable
`instanceId`. The `name` property is the one to display for an instance.

### Actions

An action is something a plugin can do, such as `set_on` or `add_task`. It
takes JSON arguments described by a JSON Schema in the plugin's manifest, and
can list the sources it affects in `targets`, so an app showing a light can
find the actions that apply to it. Actions are always addressed to one plugin
by UUID and never fall back to another plugin.

### Categories

Apps ask for a category and item, not a plugin: `weather/location`, not
"AcmeWeather". The Pebble mobile app serves the request from whichever
installed plugin provides that item. Names are free-form, so a plugin can
offer any kind of source or action, but swapping one plugin for another only
works when plugins serving the same category use the same item and property
names. When an existing category fits, use its names.

| Category | Items | Provided by |
|----------|-------|-------------|
| `weather` | `location`, `hour` | Built in |
| `calendar` | `event` | Built in |
| `phone` | `phone_state` | Built in |
| `music` | `track` | Built in (Android) |
| `notifications` | `notification` | Built in (Android) |
| `watch` | `switch_setting`, `number_setting`, `text_setting`, `app_setting` | Built in |
| `home` | `home_lights`, `room_lights`, `light` | Hue demo |
| `finance` | `stock` | Stocks demo |

### Shapes

A property is not typed as a number or a string. It is offered in one or
more shapes, fixed forms that an app can rely on being able to draw. The
plugin sends every shape it can and the app picks one.

| Shape | Use | Payload |
|-------|-----|---------|
| `shortText` | Up to about 7 characters | `{ text: "72°F" }` |
| `longText` | A line of text | `{ text: "Partly cloudy, breezy" }` |
| `numericValue` | A number, with a range when it has one | `{ value: 84, unit: "%", min: 0, max: 100 }` |
| `timestamp` | A moment, in seconds since the epoch, UTC | `{ value: 1716940800 }` |
| `boolean` | On or off | `{ value: true }` |
| `icon` | A monochrome glyph | `{ pixels, palette, width, height }` |
| `image` | A colour bitmap | `{ pixels, palette, width, height }` |

`unit`, `min` and `max` are optional. `icon` and `image` are 4-bit palettised
bitmaps, base64-encoded, and are only produced when the subscription asks
for them with `iconPixelSize`. A property or shape that is missing from an
update means the plugin cannot serve it right now; check before drawing.

Shapes let a design be built around a slot rather than around one data
source. A gauge can show anything that has a `numericValue` with a range:
battery, UV index, a light's brightness. A small text slot can show any
`shortText`.

### Permissions

Permissions run in two directions.

A plugin declares what it needs in `usesPermissions` in its manifest. Network
access is enforced: a plugin can only reach the hosts it declares under
`Internet`, and needs `LocalNetwork` to reach devices on the local network.

```json
"usesPermissions": [
  "LocalNetwork",
  { "name": "Internet", "parameters": { "domains": ["api.example.com"] } }
]
```

A source or action can require permissions of its callers. `calendar/event`
requires `Calendar`, `notifications/notification` requires `Notifications`
and `weather/*` requires `Location`. A watchapp declares the permissions it
needs in the `pebble` section of its `package.json`:

```json
"usesPermissions": ["Location"]
```

Subscribing to a source, or invoking an action, without the permission it
requires fails with `PERMISSION_DENIED`. In the preview the declarations are
checked but the user is never asked to approve them. Approval at install
time and on request is planned before plugins are released.


## Using Plugins from PebbleKit JS

A watchapp or watchface uses plugins from its PebbleKit JS code. The four
functions below are added to the `Pebble` object when the preview is on. On
both Android and iOS they are implemented by the Pebble mobile app; the
source is `libpebble3/src/androidMain/assets/startup.js` and
`libpebble3/src/commonMain/kotlin/io/rebble/libpebblecommon/js/PrivatePKJSInterface.kt`.

There are two ways to decide what to read. A face that knows what it wants
hard-codes the category, item and properties, as `weather-face` does with
`weather/location`, and works with whichever weather plugin is installed. An
app that lets the user choose calls `Pebble.enumeratePlugins()` and offers
the result on a settings page, filtered to the shapes its design can draw, as
`plugin-test` does.

### Pebble.enumeratePlugins()

Returns an array describing every installed plugin, synchronously. Each entry
has `uuid`, `name`, `sources` and `actions`, copied from the plugin's
manifest:

```js
[
  {
    uuid: "2c4b7f10-9a3d-4e6b-8f21-5d0c7e9a1b34",
    name: "Stocks",
    sources: [
      {
        category: "finance",
        items: ["stock"],
        properties: { name: ["shortText"], price: ["shortText", "longText"] },
        supportsMultiple: true,
        callerPermissions: [],
        suggestedRefreshIntervalSec: 60
      }
    ],
    actions: [
      {
        name: "add_stock",
        description: "Start tracking a ticker symbol.",
        parameters: { type: "object", properties: { symbol: { type: "string" } }, required: ["symbol"] },
        targets: ["finance/stock"],
        destructive: false,
        requiresConfirmation: false,
        callerPermissions: []
      }
    ]
  }
]
```

Returns an empty array if the call fails.

### Pebble.subscribeToSource(config)

Subscribes to one item and returns an object with an `unsubscribe()` method.
`config` is an object:

| Field | Required | Meaning |
|-------|----------|---------|
| `category` | Yes | Category name, for example `"weather"`. |
| `item` | Yes | Item name, for example `"location"`. |
| `properties` | No | Array of property names. A hint to the plugin; omit it for everything. |
| `plugin` | No | UUID of a preferred plugin. Used when that plugin is installed and serves the item; otherwise another plugin serving the item is used. |
| `iconPixelSize` | No | `{ w, h }`. Ask only when the app will draw `icon` or `image` shapes. |
| `onData` | No | Called with an envelope on every update. |
| `onError` | No | Called with `{ code, message }`. |

The call throws if `config` is missing `category` or `item`. All other
failures arrive through `onError`.

```js
var subscription = Pebble.subscribeToSource({
  category: 'weather',
  item: 'location',
  properties: ['name', 'temperature', 'condition'],
  iconPixelSize: { w: 48, h: 48 },
  onData: function (envelope) {
    var here = envelope.instances[0];
    if (!here) return;
    var p = here.properties;
    Pebble.sendAppMessage({
      place: p.name.shortText.text,
      temp: p.temperature.shortText.text
    });
  },
  onError: function (err) {
    console.log(err.code + ': ' + err.message);
  }
});

// Later, or let it end with the app:
subscription.unsubscribe();
```

Every update is an envelope. `pluginUuid` says which plugin answered, which
matters when `plugin` was given as a preference. `validUntilMs` is optional.

```js
{
  pluginUuid: "...",
  validUntilMs: 1716940000000,
  instances: [
    {
      instanceId: "3",
      properties: {
        name:       { shortText: { text: "Kitchen" } },
        brightness: { numericValue: { value: 64, unit: "%", min: 0, max: 100 },
                      shortText:    { text: "64%" } }
      }
    }
  ]
}
```

While an app is subscribed, a JavaScript plugin is asked for fresh data
every `suggestedRefreshIntervalSec` from its manifest (300 seconds when not
set), or sooner when the plugin calls `Pebble.refreshSources()` or one of
its actions reports the item in `refreshed`. Subscriptions end when the
app's JavaScript stops.

### Pebble.invokeAction(config)

Invokes one action on one plugin and returns a Promise. The Promise always
resolves; failures are reported in the result object, never by rejection.

| Field | Required | Meaning |
|-------|----------|---------|
| `plugin` | Yes | UUID of the plugin. There is no fallback to another plugin. |
| `action` | Yes | Action name from the plugin's manifest. |
| `args` | No | Object matching the action's `parameters` schema. Defaults to `{}`. |
| `timeoutMs` | No | How long to wait, 1 to 60000. Defaults to 15000. |

The call throws if `plugin` or `action` is missing. Arguments named in the
schema's `required` list must be present or the result is `INVALID_ARGS`.

```js
Pebble.invokeAction({
  plugin: '6f9c1a44-3d1e-4b8a-9c2f-0d5e7a1b3c40',
  action: 'set_on',
  args: { item: 'light', instanceId: '3', on: false }
}).then(function (result) {
  if (result.ok) {
    console.log(result.text);         // "Kitchen off."
    console.log(result.refreshed);    // ["home/light"]
  } else {
    console.log(result.code + ': ' + result.message);
  }
});
```

A successful result is `{ ok: true, text, refreshed }`, where `text` is a
short string to show the user and `refreshed` lists the `category/item`
sources the action changed. A failed result is `{ ok: false, code, message }`.

### Pebble.sendConfigMessage(message)

Sends `message` (any JSON value) to the app's own settings page while that
page is open. There is no reply and nothing happens when no page is open.
The page receives it as a `message` event with `e.target` set to `"pkjs"`
and `e.data` set to the message. See [Settings Pages](#settings-pages).

```js
Pebble.sendConfigMessage({ type: 'values', values: values });
```

### Error Codes

`onError` and a failed action result carry one of these codes in `code`:

| Code | Meaning |
|------|---------|
| `PLUGIN_UNAVAILABLE` | No installed plugin serves the item, or the plugin has no such action. |
| `PERMISSION_DENIED` | The app did not declare a permission the source or action requires. |
| `RATE_LIMITED` | The plugin refused the request for now. |
| `TIMEOUT` | The plugin did not answer in time. |
| `INVALID_REQUEST` | The request could not be parsed. |
| `INVALID_ARGS` | Actions only. A required argument is missing or invalid. |
| `AUTH_REQUIRED` | Actions only. The user has to sign in on the plugin's settings page. |
| `UNKNOWN` | Anything else. `message` has the detail. |


## Writing a Plugin

A plugin ships in a `.pbw`, either alongside a watchapp or watchface or on
its own as a plugin-only `.pbw` with no watch binary. It takes the UUID and
name of the `.pbw`. The simplest example to copy is `test-apps/stocks/`.

An app that fetches data from a service and displays it can be split into a
plugin and the app, in one `.pbw`. The app reads from its own plugin by
passing the `.pbw`'s UUID as `plugin`, and behaves as before. The data is then
also available to every other watchface and app.

### The Manifest

Add a `plugin` block to the `pebble` section of `package.json`:

```json
"pebble": {
  "displayName": "Stocks",
  "uuid": "2c4b7f10-9a3d-4e6b-8f21-5d0c7e9a1b34",
  "sdkVersion": "3",
  "configPage": "config.html",
  "plugin": {
    "description": "Share prices for the tickers the user picked.",
    "script": "plugin.js",
    "usesPermissions": [
      { "name": "Internet", "parameters": { "domains": ["query1.finance.yahoo.com"] } }
    ],
    "sources": [
      {
        "category": "finance",
        "items": ["stock"],
        "properties": {
          "name":  ["shortText"],
          "price": ["shortText", "longText", "numericValue"]
        },
        "supportsMultiple": true,
        "suggestedRefreshIntervalSec": 60
      }
    ],
    "actions": [
      {
        "name": "add_stock",
        "description": "Start tracking a ticker symbol.",
        "parameters": {
          "type": "object",
          "properties": { "symbol": { "type": "string" } },
          "required": ["symbol"]
        },
        "targets": ["finance/stock"]
      }
    ]
  }
}
```

| Field | Meaning |
|-------|---------|
| `description` | What the plugin does. Shown to users and intended for Index. |
| `script` | The plugin's JavaScript file. Defaults to `plugin.js`. |
| `usesPermissions` | What the plugin itself may do. See [Permissions](#permissions). |
| `oauth` | Hosted OAuth connectors the plugin may use, keyed by slug, for example `{ "todoist": {} }`. |
| `sources` | Blocks of items that share a category, properties and refresh interval. `callerPermissions` lists what a reader must hold. |
| `actions` | Each with `name`, `description`, a JSON Schema in `parameters`, `targets`, and optional `destructive`, `requiresConfirmation` and `callerPermissions`. |

`configPage` is optional and is described under [Settings Pages](#settings-pages).
The `add_stock` action is illustrative; the Stocks demo has no actions.

### The Script

A plugin runs only when it is needed: for a subscription refresh, for an
action, or while its settings page is open. It is started fresh for each
request and stopped afterwards, so it must not keep state in variables.
While an app is subscribed, the plugin is called for fresh data every
`suggestedRefreshIntervalSec`.

```js
// plugin.js
Pebble.registerSourceHandler(function (request, respond) {
  // request: { category, item, properties?, iconPixelSize? }
  if (request.category === 'finance' && request.item === 'stock') {
    loadQuotes().then(function (quotes) {
      respond.data({
        validUntilMs: Date.now() + 60000,
        instances: quotes.map(function (q) {
          return {
            instanceId: q.symbol,
            properties: {
              name:  { shortText: { text: q.name } },
              price: { shortText: { text: '$' + q.price },
                       numericValue: { value: q.price, unit: '$' } }
            }
          };
        })
      });
    });
    return;
  }
  respond.error('PLUGIN_UNAVAILABLE');
});

Pebble.registerActionHandler(function (request, respond) {
  // request: { action, args }
  addStock(request.args.symbol).then(function () {
    respond.ok({ text: 'Added.', refreshed: ['finance/stock'] });
  }, function (e) {
    respond.error('UNKNOWN', String(e));
  });
});
```

The handlers can return a Promise; a rejection is reported as `UNKNOWN`. A
request with no handler registered fails with `PLUGIN_UNAVAILABLE`.

The script has these APIs and no others. Unlike PebbleKit JS, a plugin does
not run in a WebView and cannot use browser APIs beyond this list.

* `fetch()` for HTTP, to the hosts in `usesPermissions` only. A request to
  any other host fails like a network error. Plain HTTP to devices on the
  local network needs `LocalNetwork`.

* `WebSocket`, under the same host rules. A blocked host fires `error` then
  `close`. Binary frames arrive as `ArrayBuffer`. Sockets are closed when the
  request ends, so a socket lives only for the request that opened it.

* `localStorage`, shared with the PebbleKit JS of the same `.pbw`. Use it
  for state that must survive between requests.

* `Pebble.refreshSources(["finance/stock"])` when data changes outside a
  request, for example when the user adds a ticker on the settings page.

* `Pebble.oauth` for signing in with an OAuth provider without the plugin
  holding a client secret. Declare the connector in the manifest under
  `oauth`, then call `Pebble.oauth.authorize("todoist")` for a token and
  `Pebble.oauth.refresh("todoist", refreshToken)` to renew it. The connector
  has to be registered with the Pebble appstore; see `test-apps/todoist/`.

* `console.log()`, `info()`, `warn()` and `error()`.

Return every property and shape the plugin can. Text shapes cost nothing once
the data is loaded, and the reading app picks the one it needs. Produce
`icon` and `image` only when the request has `iconPixelSize`.

### Settings Pages

Set `configPage` in the `pebble` section of `package.json` to an HTML file in
the project, which is bundled into the `.pbw`, or to a URL. When it is set
and the preview is on, the Pebble mobile app opens that page instead of
firing the `showConfiguration` event, and the page can exchange messages with
the `.pbw`'s scripts while it is open. Pages without `configPage` keep the
flow described in {% guide_link user-interfaces/app-configuration %}.

In the page, `Pebble.sendMessage(target, message)` sends to `"plugin"` or
`"pkjs"` and returns a Promise that resolves with the script's reply.
`Pebble.addEventListener("ready", fn)` fires once for each script that is
up, with `e.target` naming it, and `Pebble.addEventListener("message", fn)`
receives pushes from `Pebble.sendConfigMessage()` with `e.target` and
`e.data`. Wait for `ready` before sending: the plugin is started when the page
opens.

```js
// in the page
Pebble.addEventListener('ready', function (e) {
  if (e.target !== 'plugin') return;
  Pebble.sendMessage('plugin', { type: 'listTickers' }).then(function (reply) {
    render(reply.tickers);
  });
});

// in plugin.js
Pebble.registerConfigHandler(function (message, respond) {
  respond({ tickers: tickers() });
});

// in the app's PebbleKit JS
Pebble.addEventListener('configmessage', function (e) {
  e.respond({ theme: theme() });
});
```

In PebbleKit JS the `configmessage` event has `e.data` and `e.respond()`.
Call `e.respond()` exactly once; a message with no `configmessage` listener
is answered with `{ error: "no configmessage listener registered" }`, and a
reply that does not arrive within 30 seconds resolves the page's Promise with
`null`.

The `plugin-test` dashboard uses this to fill its settings page from
`Pebble.enumeratePlugins()`, send each change straight to PebbleKit JS so the
watch updates as the user edits, and push the live readings back so each
option is labelled with its current value.


## Packaging and Sideloading

`pebble build` does not put `plugin.js` or `config.html` into the `.pbw` and
cannot build a plugin-only `.pbw`. Use `scripts/pack-plugin-pbw.py` from the
mobile app repository instead:

```nc|text
$ scripts/pack-plugin-pbw.py path/to/my-plugin
```

If the project has a watchapp (`src/c`), the script runs `pebble build` and
adds the plugin files to the result. Otherwise it writes a plugin-only
`.pbw` directly from `package.json`, without the SDK. The output is
`build/<name>.pbw`.

Install the `.pbw` on the phone the same way as any sideloaded app, for
example with `pebble install` through the
{% guide_link tools-and-resources/developer-connection "Developer Connection" %}
or by opening the file on the phone. Plugin-only `.pbw`s appear on the
*Plugins* tab of the *Apps* screen and are never sent to the watch.


## Limitations

* The API is a preview and will change. Apps and plugins that use it should
  not be published to the appstore.

* Plugins cannot be called from Index 01 yet. See
  [Index 01 and Plugins](/index-01/plugins/).

* Permissions are declared and checked but the user is not asked to approve
  them.

* There is no watch-side C or Alloy API. An app needs PebbleKit JS to read a
  plugin.

* `music` and `notifications` are only provided on Android.

* The `pebble` tool and CloudPebble do not package plugins; use
  `pack-plugin-pbw.py`.

* There is no appstore category for plugins and no way for the user to
  choose a preferred plugin when several serve the same item. One of the
  installed plugins that serves the item answers, unless the subscription
  names one with `plugin`.

* Plugins cannot call other plugins, and PebbleKit Android and PebbleKit iOS
  cannot use them.
