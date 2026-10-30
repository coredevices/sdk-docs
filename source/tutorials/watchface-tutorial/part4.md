---
# Copyright 2026 Core Devices LLC
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

layout: tutorials/tutorial
tutorial: watchface
tutorial_part: 4

title: Adding Weather with Plugins
description: |
  How to read the weather from the Pebble app's weather plugin using
  PebbleKit JS and display it on your watchface.
permalink: /tutorials/watchface-tutorial/part4/
generate_toc: true
platform_choice: true
---

Up until now, everything in our watchface has been running entirely on the
watch. In this part we take a big step: communicating with the phone to get
live weather data.

We will use [PebbleKit JS](/guides/communication/using-pebblekit-js/) to run
JavaScript on the connected phone, read the weather from the Pebble app's
weather [plugin](/guides/plugins/preview/), and send it to the watch using
``AppMessage``. The Pebble app already fetches the weather for the user's
locations from the provider they chose, so the watchface doesn't need its own
weather API, API key or location lookup.

This section continues from
[*Part 3*](/tutorials/watchface-tutorial/part3/).

By the end, our watchface will show the current temperature and weather
conditions:

{% screenshot_viewer %}
{
  "image": "/images/tutorials/watchface-tutorial/part4.png",
  "default": "emery",
  "platforms": [
    {"hw": "aplite", "wrapper": "steel-black"},
    {"hw": "basalt", "wrapper": "time-red"},
    {"hw": "chalk", "wrapper": "time-round-rosegold-14"},
    {"hw": "diorite", "wrapper": "pebble2-black"},
    {"hw": "emery", "wrapper": "core-time2-red"},
    {"hw": "gabbro", "wrapper": "core-time-round2-black-20"}
  ]
}
{% endscreenshot_viewer %}


## How PebbleKit JS Works

Pebble watches cannot access the internet directly. Instead, they communicate
with a JavaScript environment called **PebbleKit JS** (PKJS) that runs on the
connected phone. Your JS code can read data from plugins in the Pebble app,
make HTTP requests, and send data back to the watch using ``AppMessage``.

```text
┌─────────────┐          ┌──────────────────┐          ┌──────────────────┐
│   Watch     │          │  Phone (PKJS)    │          │  Pebble app      │
│             │          │                  │          │                  │
│             │          │  index.js      ──┼─ sub ──> │  weather plugin  │
│             │          │                  │          │                  │
│  <── msg ───┼──────────┤  <── updates ────┼──────────┤                  │
│             │          │                  │          │                  │
│  request  ──┼── msg ──>│  → resends the   │          │                  │
│  <── msg ───┼──────────┤    latest reading│          │                  │
└─────────────┘          └──────────────────┘          └──────────────────┘
```

The flow for weather is:

1. When PKJS starts, it subscribes to the weather from the Pebble app's
   weather plugin.
2. The plugin sends the current weather right away, and again whenever it
   changes.
3. PKJS sends each reading to the watch via ``AppMessage``.
4. The watch receives the message and updates the display.

All communication between watch and phone uses ``AppMessage`` - a key-value
dictionary system. You define the keys in `package.json` and they become
constants in both C and JS.


## Preparing the Layout

We need a new ``TextLayer`` for the weather data. Add the declaration at the top
of the file:

```c
static TextLayer *s_weather_layer;
```

Create it in `main_window_load()`. We place it at the bottom of the screen so
it stays out of the way of the centered time and date block:

```c
// Create weather TextLayer - aligned to the bottom of the screen
int weather_y = bounds.size.h - PBL_IF_ROUND_ELSE(40, 30);
s_weather_layer = text_layer_create(
    GRect(0, weather_y, bounds.size.w, 25));
text_layer_set_background_color(s_weather_layer, GColorClear);
text_layer_set_text_color(s_weather_layer, GColorWhite);
text_layer_set_font(s_weather_layer, fonts_get_system_font(FONT_KEY_GOTHIC_18));
text_layer_set_text_alignment(s_weather_layer, GTextAlignmentCenter);
text_layer_set_text(s_weather_layer, "Loading...");
```

Add it as a child layer and destroy it in `main_window_unload()`:

```c
// In main_window_load()
layer_add_child(window_layer, text_layer_get_layer(s_weather_layer));

// In main_window_unload()
text_layer_destroy(s_weather_layer);
```


## Setting Up AppMessage

``AppMessage`` is the communication channel between the watch and phone.
Messages are key-value dictionaries.

^CP^ In CloudPebble, go to **Settings** on the left sidebar, scroll down to
**PebbleKit JS Message Keys** and add the following keys: `TEMPERATURE`,
`CONDITIONS`, and `REQUEST_WEATHER`.

^LC^ First, define the message keys in `package.json`. Add these to the `pebble`
section:

{% platform local %}
```json
"messageKeys": [
  "TEMPERATURE",
  "CONDITIONS",
  "REQUEST_WEATHER"
]
```
{% endplatform %}

The message keys
become `MESSAGE_KEY_TEMPERATURE`, `MESSAGE_KEY_CONDITIONS`, and
`MESSAGE_KEY_REQUEST_WEATHER` constants in C.

Now create the AppMessage callbacks in your C file. These go above `init()`:

```c
static void inbox_received_callback(DictionaryIterator *iterator, void *context) {

}

static void inbox_dropped_callback(AppMessageResult reason, void *context) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Message dropped!");
}

static void outbox_failed_callback(DictionaryIterator *iterator, AppMessageResult reason, void *context) {
  APP_LOG(APP_LOG_LEVEL_ERROR, "Outbox send failed!");
}

static void outbox_sent_callback(DictionaryIterator *iterator, void *context) {
  APP_LOG(APP_LOG_LEVEL_INFO, "Outbox send success!");
}
```

Register the callbacks and open AppMessage in `init()`. It is important to
register callbacks *before* opening AppMessage so no messages are missed:

```c
// Register AppMessage callbacks
app_message_register_inbox_received(inbox_received_callback);
app_message_register_inbox_dropped(inbox_dropped_callback);
app_message_register_outbox_failed(outbox_failed_callback);
app_message_register_outbox_sent(outbox_sent_callback);

// Open AppMessage
const int inbox_size = 128;
const int outbox_size = 128;
app_message_open(inbox_size, outbox_size);
```


## Declaring Permissions

Plugins only share data with apps that declare what they need, and the user
stays in control of it. The weather is tied to the user's location, so reading
it needs the `Location` permission.

^LC^ Add `usesPermissions` to the `pebble` section of `package.json`:

{% platform local %}
```json
"usesPermissions": [
  "Location"
]
```
{% endplatform %}

Permissions need the app to be built with `manifestVersion` 2, which is the
default from SDK 4.44. Users also need plugins turned on in the Pebble app
(**Settings → Plugins → Plugins / permissions preview**).

Our watchface doesn't declare `Internet`, so it can't send the user's location
anywhere. By default, the Pebble app lets an app like that read the weather
without asking the user. If the user has chosen to be asked, the first reading
fails with `PERMISSION_DENIED` until they answer, and the user can allow or
deny the permission on the app's page in the Pebble app at any time. See
[Permissions](/guides/plugins/preview/#permissions) for the details.

> **Note:** The watchface doesn't need the `location` capability or
> `navigator.geolocation`. The weather plugin already serves the weather for
> the user's locations.


## Writing the JavaScript

^CP^ Click **Add New** next to **Source Files** in the left sidebar, select
**JavaScript file**, and name it (e.g., `weather.js`). This code runs on the
phone whenever the watchface is open.

^LC^ Create a new file at `src/pkjs/index.js`. This code runs on the phone whenever
the watchface is open.

We keep the latest reading so we can send it again whenever the watch asks for
it:

```js
var latestWeather = null;

function sendWeather() {
  if (!latestWeather) {
    return;
  }
  Pebble.sendAppMessage(latestWeather,
    function(e) { console.log('Weather info sent!'); },
    function(e) { console.log('Error sending weather info!'); }
  );
}
```

The weather plugin reports temperatures in the units the user picked in the
Pebble app, either `°C` or `°F`. Our watch code expects Celsius, so add a helper
to convert:

```js
function toCelsius(reading) {
  if (reading.unit === '°F') {
    return (reading.value - 32) * 5 / 9;
  }
  return reading.value;
}
```

Now subscribe to the weather with `Pebble.subscribeToSource()`. We ask for the
`location` item of the `weather` category, which serves one instance per
weather location the user set up in the Pebble app, in their order. We use the
first one:

```js
function subscribeToWeather() {
  Pebble.subscribeToSource({
    category: 'weather',
    item: 'location',
    properties: ['temperature', 'condition'],
    onData: function(update) {
      var here = update.instances[0];
      if (!here) {
        return;
      }

      // Any property can be missing, so check before using it
      var temperature = here.properties.temperature;
      var condition = here.properties.condition;
      if (!temperature || !temperature.numericValue ||
          !condition || !condition.shortText) {
        return;
      }

      latestWeather = {
        'TEMPERATURE': Math.round(toCelsius(temperature.numericValue)),
        'CONDITIONS': condition.shortText.text
      };
      sendWeather();
    },
    onError: function(err) {
      console.log('Weather unavailable: ' + err.code + ' ' + err.message);
    }
  });
}
```

Each property comes in one or more **shapes**. We read `temperature` as a
`numericValue` (a number with a `unit`) and `condition` as a `shortText`, a
short label like "Cloudy". `onData` is called with the current weather right
away, and again whenever it changes, so we don't need to poll. An error doesn't
end the subscription: the next update can still succeed.

> **Why a plugin?** The user picks their weather provider and locations once in
> the Pebble app, and every watchface that uses the weather plugin follows
> them. Your watchface works with whichever weather plugin the user has
> installed.

Finally, set up the event listeners:

```js
Pebble.addEventListener('ready',
  function(e) {
    console.log('PebbleKit JS ready!');
    subscribeToWeather();
  }
);

Pebble.addEventListener('appmessage',
  function(e) {
    console.log('AppMessage received!');
    if (e.payload['REQUEST_WEATHER']) {
      sendWeather();
    }
  }
);
```

When the JS environment starts (`ready`), we subscribe to the weather. The
`appmessage` listener checks for the `REQUEST_WEATHER` key and sends the latest
reading again, so the watch can ask for it whenever it needs to.


## Processing Weather Data on the Watch

Back in the C file, fill in `inbox_received_callback()` to extract the weather
data and display it:

```c
static void inbox_received_callback(DictionaryIterator *iterator, void *context) {
  Tuple *temp_tuple = dict_find(iterator, MESSAGE_KEY_TEMPERATURE);
  Tuple *conditions_tuple = dict_find(iterator, MESSAGE_KEY_CONDITIONS);

  if (temp_tuple && conditions_tuple) {
    static char temperature_buffer[8];
    static char conditions_buffer[32];
    static char weather_layer_buffer[42];

    snprintf(temperature_buffer, sizeof(temperature_buffer), "%d°C", (int)temp_tuple->value->int32);
    snprintf(conditions_buffer, sizeof(conditions_buffer), "%s", conditions_tuple->value->cstring);
    snprintf(weather_layer_buffer, sizeof(weather_layer_buffer), "%s %s", temperature_buffer, conditions_buffer);
    text_layer_set_text(s_weather_layer, weather_layer_buffer);
  }
}
```

We use ``dict_find()`` to look up each key. Numbers arrive as `int32`, strings
as `cstring`.


## Keeping the Weather Current

There's nothing more to do here. The subscription pushes a new reading
whenever the weather changes, and PKJS forwards it to the watch, so the
watchface stays up to date without polling.

In the emulator, the weather plugin serves sample weather and every permission
is granted, so the watchface shows the weather as soon as it starts.


## Conclusion

In this part we learned how to:

1. Set up ``AppMessage`` for watch-phone communication.
2. Write PebbleKit JS to run on the phone.
3. Declare the `Location` permission in `usesPermissions`.
4. Read the weather from the weather plugin with `Pebble.subscribeToSource()`.
5. Send the data to the watch.
6. Display received data in a ``TextLayer``.

Your watchface now shows live weather data! Check your code against
[the source for this part](https://github.com/coredevices/c-watchface-tutorial/tree/main/part4).


## What's Next?

In the next part we will add Timeline Peek support, so the watchface adapts
gracefully when the system overlays part of the screen.

[Go to Part 5 &rarr; >{wide,bg-dark-red,fg-white}](/tutorials/watchface-tutorial/part5/)
