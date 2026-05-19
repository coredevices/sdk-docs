---
# Copyright 2025 Core Devices LLC
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
tutorial: alloy-watchface
tutorial_part: 6

title: User Settings with localStorage and Clay
description: |
  How to persist user preferences using localStorage and add a
  phone-side settings page with Clay so users can customize their watchface.
permalink: /tutorials/alloy-watchface-tutorial/part6/
generate_toc: true
platform_choice: true
---

The finishing touch for any great watchface is letting users make it their own.
In this final part we will add user settings using `localStorage` - a simple
key-value store built right into Alloy - and then add a phone-side configuration
page using [Clay for Pebble](https://github.com/pebble-dev/clay) so users can
change settings from their phone. Users will be able to choose background
and text colors, toggle the date display, pick temperature units, and choose
between 12-hour and 24-hour time formats.

Here is an example of a customized watchface:

{% screenshot_viewer %}
{
  "image": "/images/tutorials/alloy-watchface-tutorial/part6.png",
  "default": "emery",
  "platforms": [
    {"hw": "emery", "wrapper": "core-time2-red"},
    {"hw": "gabbro", "wrapper": "core-time-round2-black-20"}
  ]
}
{% endscreenshot_viewer %}

This section continues from
[*Part 5*](/tutorials/alloy-watchface-tutorial/part5/).


## How localStorage Works in Alloy

Alloy provides the standard Web `localStorage` API for persistent storage.
Data is saved to flash and survives app restarts. The API is straightforward:

- `localStorage.setItem(key, value)` - store a string value
- `localStorage.getItem(key)` - retrieve a value (or `null` if missing)
- `localStorage.removeItem(key)` - delete a value

Since `localStorage` only stores strings, we use `JSON.stringify()` and
`JSON.parse()` to store structured data like our settings object.


## Defining Default Settings

Add a defaults object near the top of `main.js`, after the font declarations:

```js
const DEFAULT_SETTINGS = {
    backgroundColor: { r: 0, g: 0, b: 0 },
    textColor: { r: 255, g: 255, b: 255 },
    useFahrenheit: false,
    showDate: true,
    use24Hour: true
};
```

We store colors as `{ r, g, b }` objects so they serialize cleanly to JSON.


## Loading and Saving Settings

Add two helper functions:

```js
function loadSettings() {
    const stored = localStorage.getItem("settings");
    if (stored) {
        try {
            return { ...DEFAULT_SETTINGS, ...JSON.parse(stored) };
        } catch (e) {
            console.log("Failed to parse settings");
        }
    }
    return { ...DEFAULT_SETTINGS };
}

function saveSettings() {
    localStorage.setItem("settings", JSON.stringify(settings));
}

let settings = loadSettings();
```

The spread pattern `{ ...DEFAULT_SETTINGS, ...JSON.parse(stored) }` is
important. It ensures that if we add new settings in a future version, they
automatically get default values even when loading old saved data. This is the
Alloy equivalent of the C pattern of calling `prv_default_settings()` before
`persist_read_data()`.


## Creating Colors from Settings

Replace the hardcoded `black` and `white` color declarations with
settings-driven ones:

```js
let bgColor = render.makeColor(settings.backgroundColor.r,
    settings.backgroundColor.g, settings.backgroundColor.b);
let textColor = render.makeColor(settings.textColor.r,
    settings.textColor.g, settings.textColor.b);

function updateColors() {
    bgColor = render.makeColor(settings.backgroundColor.r,
        settings.backgroundColor.g, settings.backgroundColor.b);
    textColor = render.makeColor(settings.textColor.r,
        settings.textColor.g, settings.textColor.b);
}
```

The `updateColors()` function recreates the Poco color values whenever settings
change. Call it after loading new settings.


## Applying Settings to the Display

Update `drawScreen()` to use the settings-driven colors and respect the
`showDate` toggle:

```js
function drawScreen(event) {
    const now = event?.date ?? lastDate;
    if (event?.date) lastDate = event.date;

    render.begin();
    render.fillRectangle(bgColor, 0, 0, render.width, render.height);

    // ... battery bar and disconnect indicator ...

    // Format time as HH:MM (24h) or H:MM (12h)
    let hours = now.getHours();
    if (!settings.use24Hour) {
        hours = hours % 12 || 12;
    }
    const hoursStr = String(hours).padStart(2, "0");
    const minutes = String(now.getMinutes()).padStart(2, "0");
    const timeStr = `${hoursStr}:${minutes}`;

    // Draw time
    let width = render.getTextWidth(timeStr, timeFont);
    render.drawText(timeStr, timeFont, textColor,
        (render.width - width) / 2, timeY);

    // Draw date if setting is enabled
    if (settings.showDate) {
        // ... date drawing code ...
        render.drawText(dateStr, dateFont, textColor,
            (render.width - width) / 2, dateY);
    }

    // ... weather display ...

    render.end();
}
```

The key changes:
- `bgColor` replaces `black` for the background fill
- `textColor` replaces `white` for all text drawing
- The date block is wrapped in `if (settings.showDate)`
- Time formatting respects the `use24Hour` setting - when disabled, hours are
  converted to 12-hour format using `hours % 12 || 12` (the `|| 12` turns
  midnight's `0` into `12`)

Also update the battery bar border to use `textColor` instead of hardcoded
white, so it matches the user's color choice:

```js
function drawBatteryBar() {
    // ...
    render.fillRectangle(textColor, barX, barY, barWidth, barHeight);
    render.fillRectangle(bgColor, barX + 1, barY + 1, barWidth - 2, barHeight - 2);
    // ...
}
```


## Temperature Unit Support

Update the weather display to show the correct unit:

```js
    if (weather) {
        const unit = settings.useFahrenheit ? "F" : "C";
        const weatherStr = `${weather.temp}°${unit} ${weather.conditions}`;
        // ...
    }
```

In `fetchWeather()`, pass the unit preference to Open-Meteo so the API returns
the temperature in the correct unit directly:

```js
async function fetchWeather(latitude, longitude) {
    // ...
    const params = {
        latitude,
        longitude,
        current: "temperature_2m,weather_code"
    };

    if (settings.useFahrenheit) {
        params.temperature_unit = "fahrenheit";
    }

    const url = new URL("https://api.open-meteo.com/v1/forecast");
    url.search = new URLSearchParams(params);
    // ...
}
```

Open-Meteo supports a `temperature_unit` parameter natively, so we do not need
to convert on the watch - the API handles it for us.


## Caching Weather Data

Since weather data is expensive to fetch (it requires a phone connection and
network request), we cache it in `localStorage` so the watchface can show
recent weather immediately on startup:

```js
function loadCachedWeather() {
    const cached = localStorage.getItem("weather");
    const cachedTime = localStorage.getItem("weatherTime");

    if (cached && cachedTime) {
        const age = Date.now() - Number(cachedTime);
        // Use cache if less than 1 hour old
        if (age < 60 * 60 * 1000) {
            try {
                weather = JSON.parse(cached);
                console.log("Using cached weather");
                return true;
            } catch (e) {
                console.log("Failed to parse cached weather");
            }
        }
    }
    return false;
}

function saveWeather() {
    if (weather) {
        localStorage.setItem("weather", JSON.stringify(weather));
        localStorage.setItem("weatherTime", String(Date.now()));
    }
}
```

Call `loadCachedWeather()` at startup, and call `saveWeather()` at the end of
a successful `fetchWeather()`:

```js
// At module level
loadCachedWeather();

// Inside fetchWeather(), after setting weather:
saveWeather();
drawScreen();
```

This gives users instant weather display on app launch instead of "Loading..."
while waiting for the phone connection and API response.


## Adding a Settings Page with Clay

So far our settings only have default values and no way for the user to change
them. Let's add a phone-side configuration page using
[Clay for Pebble](https://github.com/pebble-dev/clay). Clay generates a
settings UI on the phone from a simple JSON definition and sends the values to
the watch via AppMessage - the same mechanism used by the C tutorial.


## Installing Clay

^CP^ In CloudPebble, go to the **Dependencies** section in the left sidebar and add
`@rebble/clay` as a NPM Dependency.

^LC^ Clay is available as a Pebble Package. Install it from your project directory:

{% platform local %}
```text
$ pebble package install @rebble/clay
```
{% endplatform %}

This adds `@rebble/clay` to the `dependencies` in `package.json`.


## Enabling Configuration

^CP^ In CloudPebble, go to **Settings** and add `configurable` to the
**Capabilities** list so the gear icon appears next to your watchface in the
phone app.

^LC^ For the gear icon to appear next to your watchface in the phone app, add
`configurable` to the `capabilities` array in `package.json`:

{% platform local %}
```json
"capabilities": [
  "location",
  "configurable"
]
```
{% endplatform %}


## Defining Message Keys

^CP^ In CloudPebble, go to **Settings** and add the following message keys in the
**PebbleKit JS Message Keys** section: `BackgroundColor`, `TextColor`,
`TemperatureUnit`, `ShowDate`, and `HourFormat`.

^LC^ Clay sends settings to the watch as AppMessage key-value pairs. Add message
keys for each setting to `package.json`:

{% platform local %}
```json
"messageKeys": [
  "BackgroundColor",
  "TextColor",
  "TemperatureUnit",
  "ShowDate",
  "HourFormat"
]
```
{% endplatform %}

These keys are used by Clay in the PKJS layer and by the `Message` class on the
watch to identify which setting is being sent.


## Creating the Clay Configuration

^CP^ Click **Add New** next to **Source Files**, select **JavaScript file**, and
name it `config.js`. Clay uses a simple JSON array of sections and fields:

^LC^ Create `src/pkjs/config.js` with the configuration definition. Clay uses a
simple JSON array of sections and fields:

```js
module.exports = [
  {
    "type": "heading",
    "defaultValue": "Watchface Settings"
  },
  {
    "type": "text",
    "defaultValue": "Customize your watchface appearance and preferences."
  },
  {
    "type": "section",
    "items": [
      {
        "type": "heading",
        "defaultValue": "Colors"
      },
      {
        "type": "color",
        "messageKey": "BackgroundColor",
        "defaultValue": "0x000000",
        "label": "Background Color"
      },
      {
        "type": "color",
        "messageKey": "TextColor",
        "defaultValue": "0xFFFFFF",
        "label": "Text Color"
      }
    ]
  },
  {
    "type": "section",
    "items": [
      {
        "type": "heading",
        "defaultValue": "Preferences"
      },
      {
        "type": "toggle",
        "messageKey": "TemperatureUnit",
        "label": "Use Fahrenheit",
        "defaultValue": false
      },
      {
        "type": "toggle",
        "messageKey": "ShowDate",
        "label": "Show Date",
        "defaultValue": true
      },
      {
        "type": "toggle",
        "messageKey": "HourFormat",
        "label": "Use 24-Hour Format",
        "defaultValue": true
      }
    ]
  },
  {
    "type": "submit",
    "defaultValue": "Save Settings"
  }
];
```

This is the same configuration used in the C tutorial. Each `messageKey`
matches a key in `package.json`. The `color` type provides a color picker and
`toggle` gives a switch.


## Initializing Clay in PKJS

^CP^ Open your JavaScript file in the CloudPebble editor and initialize Clay
before the proxy:

^LC^ Update `src/pkjs/index.js` to initialize Clay before the proxy:

```js
var Clay = require('@rebble/clay');
var clayConfig = require('./config');
var clay = new Clay(clayConfig);

const moddableProxy = require("@moddable/pebbleproxy");
Pebble.addEventListener('ready', moddableProxy.readyReceived);
Pebble.addEventListener('appmessage', moddableProxy.appMessageReceived);
```

Clay automatically handles the `showConfiguration` and `webviewClosed` events
(opening the settings page and sending results back). The proxy continues to
handle `ready` and `appmessage` for fetch and location requests from the watch.
There is no conflict since they use different event types.


## Receiving Settings on the Watch

When the user saves settings on the phone, Clay sends them as an AppMessage.
On the watch side, we use the `Message` class from `pebble/message` to receive
them. Add the import at the top of `main.js`:

```js
import Message from "pebble/message";
```

Then add a `Message` instance at the end of the file:

```js
const message = new Message({
    keys: ["BackgroundColor", "TextColor", "TemperatureUnit", "ShowDate", "HourFormat"],
    onReadable() {
        const msg = this.read();

        const bg = msg.get("BackgroundColor");
        if (bg !== undefined) {
            settings.backgroundColor = { r: (bg >> 16) & 0xFF, g: (bg >> 8) & 0xFF, b: bg & 0xFF };
        }
        const tc = msg.get("TextColor");
        if (tc !== undefined) {
            settings.textColor = { r: (tc >> 16) & 0xFF, g: (tc >> 8) & 0xFF, b: tc & 0xFF };
        }
        const tu = msg.get("TemperatureUnit");
        if (tu !== undefined) {
            settings.useFahrenheit = tu === 1;
        }
        const sd = msg.get("ShowDate");
        if (sd !== undefined) {
            settings.showDate = sd === 1;
        }
        const hf = msg.get("HourFormat");
        if (hf !== undefined) {
            settings.use24Hour = hf === 1;
        }

        saveSettings();
        updateColors();
        drawScreen();

        // Re-fetch weather if temperature unit changed
        if (tu !== undefined) {
            requestLocation();
        }
    }
});
```

The `keys` array tells `Message` which AppMessage keys to listen for - these
must match the `messageKeys` in `package.json`.

Clay sends colors as `0x00RRGGBB` int32 values. We extract the red, green, and
blue components with bit shifts:

- Red: `(value >> 16) & 0xFF`
- Green: `(value >> 8) & 0xFF`
- Blue: `value & 0xFF`

Toggles arrive as int32 values where `1` means on and `0` means off.

After updating the settings object, we save to `localStorage`, recreate the
Poco color values with `updateColors()`, and redraw the screen. If the
temperature unit changed, we also re-fetch weather so the API returns values
in the correct unit.


## Trying It Out

^CP^ Click the **play** button to compile and install, then tap the gear icon in
the emulator to open the settings page.

^LC^ Build and install your watchface, then use `pebble emu-app-config` to open
the settings page in your browser:

{% platform local %}
```text
$ pebble build && pebble install --emulator emery
$ pebble emu-app-config
```
{% endplatform %}

Try changing the background color, text color, and toggling the date,
temperature unit, and hour format - you should see the watchface update
immediately.

![Settings page on phone](/images/tutorials/watchface-tutorial/part6-settings.gif)


## Alloy vs. C Settings

| | C (Clay) | Alloy (Clay + localStorage) |
|---|---|---|
| **Settings UI** | Clay JSON config on phone | Same Clay JSON config on phone |
| **Phone-side code** | Clay init in PKJS | Clay init + proxy in PKJS |
| **Receiving settings** | `inbox_received_callback` with `dict_find` | `Message` class with `onReadable` |
| **Storage** | `persist_write_data()` / `persist_read_data()` | `localStorage.setItem()` / `getItem()` |
| **Serialization** | Raw struct bytes | JSON strings |
| **New fields** | Must call defaults before load | Spread operator merges defaults |

The phone-side Clay setup is identical between C and Alloy - the same
`config.js` works for both. The difference is on the watch side: C uses
`dict_find` in an inbox callback to extract values, while Alloy uses the
`Message` class with a readable callback.


## Conclusion

Congratulations! You have built a complete, feature-rich Pebble watchface in
Alloy. Here is everything it includes:

1. **Digital time display** with the Jersey font and 12h/24h format option.
2. **Date display** that can be toggled on/off.
3. **Live weather** from Open-Meteo (no API key needed).
4. **Battery meter** with color-coded levels.
5. **Bluetooth disconnect** indicator.
6. **User settings** persisted with `localStorage`.
7. **Weather caching** for instant startup display.
8. **Clay configuration** for colors and preferences.

In this final part we learned how to:

- Use `localStorage` for persistent key-value storage.
- Define default settings with a spread-merge pattern.
- Apply color, display, and time format preferences dynamically.
- Pass unit preferences to the Open-Meteo API.
- Cache API responses for faster startup.
- Install and configure Clay for a phone-side settings page.
- Receive Clay settings on the watch with the `Message` class.
- Parse color and toggle values from AppMessages.

Check your code against
[the source for this part](https://github.com/coredevices/alloy-watchface-tutorial/tree/main/part6).
Now it is time to
[publish your watchface](https://developer.repebble.com/dashboard)
and share it with the world!
