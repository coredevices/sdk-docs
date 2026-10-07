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

title: Sensors and Input
description: |
  Access Pebble sensors and handle button input in Alloy apps.
guide_group: alloy
order: 4
---

Alloy provides access to Pebble hardware sensors and button input through
simple JavaScript APIs. Sensors follow the ECMA-419 Sensor Class Pattern, while
the Button class is a Pebble-specific API.

> **Note**: All code in this guide runs on the watch in `src/embeddedjs/main.js`.

## Button Input

Handle button presses using the `Button` class:

```js
import Button from "pebble/button";

new Button({
    types: ["select", "up", "down", "back"],
    onPush(down, type) {
        console.log((down ? "press " : "release ") + type);
    }
});
```

> **Note**: If your app includes `"back"` in the `types` array, the back button
> no longer exits the app automatically - press and hold back to exit instead.
> If you don't include `"back"`, pressing back exits as usual.

### Button Types

| Type | Description |
|------|-------------|
| `"select"` | Middle button (center right) |
| `"up"` | Top button |
| `"down"` | Bottom button |
| `"back"` | Back button (left side) |

### Click Recognizers

By default a `Button` reports *raw* presses and releases, as above. Since SDK
4.33, buttons can instead (or additionally) use the system's click
recognizers, which take care of repeat-while-held, long presses and
multi-clicks for you. Enable them with extra options in the constructor:

```js
import Button from "pebble/button";

new Button({
    types: ["select", "up", "down"],
    single: { repeat: 200 },  // clicks, repeating every 200ms while held
    long: { delay: 700 },     // long presses after 700ms
    onPush(down, type, recognizer, count, repeat) {
        if (recognizer === "long") {
            console.log(down ? ("long press " + type) : "long release");
        } else if (down) {
            console.log("click " + type + (repeat ? " (held)" : ""));
        }
    }
});
```

| Option | Value | Behavior |
|--------|-------|----------|
| `single` | `true` or `{ repeat }` | Fires once per click with `down = 1`. With a `repeat` interval (ms), the click fires repeatedly while the button is held, with `repeat = true` on repeats. |
| `long` | `true` or `{ delay }` | Fires with `down = 1` once the button has been held for `delay` ms (default is the system delay), and again with `down = 0` on release. |
| `multi` | `true` or `{ min, max, lastOnly, timeout }` | Recognizes sequences of `min` to `max` clicks arriving within `timeout` ms of each other. Fires with `down = 1` and `count` set to the number of clicks; with `lastOnly` it fires only for the final count. |
| `raw` | `true` | Plain press (`down = 1`) and release (`down = 0`) events. This is the default when no recognizer option is given. |

Recognizer options apply to all buttons in the `types` array, and multiple
recognizers can be combined on the same button. Two restrictions apply to the
back button: it does not support `long` (the system reserves press-and-hold
back for exiting the app), and its `raw` events are emulated, delivering the
press and release back-to-back on click.

### Button Events

The `onPush` callback receives five parameters:

- `down` - `1` when pressed, `0` when released (use it as a truthy/falsy value)
- `type` - String: which button was pressed
- `recognizer` - String: which recognizer fired (`"single"`, `"long"`,
  `"multi"` or `"raw"`)
- `count` - Number of clicks counted (e.g. for `multi` sequences)
- `repeat` - `true` when this is a repeating `single` click from holding the
  button

Callbacks that only declare `(down, type)` keep working unchanged.

## Accelerometer

Read motion data from the accelerometer:

```js
import Accelerometer from "embedded:sensor/Accelerometer";

const accel = new Accelerometer({
    onSample() {
        const sample = this.sample();
        console.log("accel " + sample.x + ", " + sample.y + ", " + sample.z);
    },
    onTap(direction) {
        console.log("single tap " + direction);
    },
    onDoubleTap(direction) {
        console.log("double tap " + direction);
    }
});

// Configure sample rate (Hz)
accel.configure({ hz: 10 });
```

### Accelerometer Sample Data

The `sample()` method returns an object with:

| Property | Description |
|----------|-------------|
| `x` | Acceleration on X axis |
| `y` | Acceleration on Y axis |
| `z` | Acceleration on Z axis |

### Accelerometer Events

| Event | Description |
|-------|-------------|
| `onSample()` | Called when new sensor data is available |
| `onTap(direction)` | Called on single tap gesture |
| `onDoubleTap(direction)` | Called on double tap gesture |

### Configuration Options

```javascript
accel.configure({
    hz: 10  // Sample rate in Hz (samples per second)
});
```

## Compass

Read the magnetic heading from the compass:

```js
import Compass from "embedded:sensor/Compass";

const compass = new Compass({
    onSample() {
        const sample = this.sample();
        console.log("heading " + sample.heading);
    }
});
```

### Compass Sample Data

| Property | Description |
|----------|-------------|
| `heading` | Magnetic heading in degrees (0-360) |

## Location

Get the user's GPS location via the phone:

```js
import Location from "embedded:sensor/Location";

const location = new Location({
    onSample() {
        const sample = this.sample();
        console.log("Location: " + sample.latitude + ", " + sample.longitude);
        this.close();
    }
});
```

The Location sensor follows the same ECMA-419 pattern as other sensors but has
a few differences:

- **One-shot** - call `this.close()` after receiving the sample. Location is a
  request, not a continuous monitor.
- **Requires the phone** - location data comes from the phone's GPS via the
  `@moddable/pebbleproxy` package.
- **Requires capability** - add `"location"` to the `capabilities` array in
  `package.json`.

### Location Sample Data

| Property | Type | Description |
|----------|------|-------------|
| `latitude` | Number | Latitude in decimal degrees |
| `longitude` | Number | Longitude in decimal degrees |

### Configuration Options

You can optionally configure the location request immediately after creating the
instance:

```js
location.configure({
    enableHighAccuracy: false,
    timeout: 5000,
    maximumAge: 0
});
```

| Option | Description |
|--------|-------------|
| `enableHighAccuracy` | Request high-accuracy GPS (uses more battery) |
| `timeout` | Maximum time in ms to wait for a location |
| `maximumAge` | Accept a cached location up to this many ms old |

### PKJS Setup for Location

The Location sensor requires the `@moddable/pebbleproxy` package. Set up
`src/pkjs/index.js`:

```js
const moddableProxy = require("@moddable/pebbleproxy");
Pebble.addEventListener('ready', moddableProxy.readyReceived);
Pebble.addEventListener('appmessage', moddableProxy.appMessageReceived);
```

No custom location code is needed in PKJS - the proxy handles GPS lookup
automatically.

## Touch

On platforms with a touchscreen (Emery, Gabbro), read raw touch points using
the `Touch` sensor exposed as `device.sensor.Touch`:

```js
const touch = new device.sensor.Touch({
    onSample() {
        const points = this.sample();
        if (!points) return;

        if (points.length === 0) {
            console.log("lift-off");
            return;
        }

        const { x, y } = points[0];
        console.log("touch " + x + ", " + y);
    }
});
```

### Touch Sample Data

`sample()` returns either a falsy value (no new data since the last call) or
an array of current contact points. An empty array signals that the last
finger has lifted off the screen.

| Property | Description |
|----------|-------------|
| `x` | X coordinate in screen pixels |
| `y` | Y coordinate in screen pixels |

### Tracking Touch State

`onSample` only tells you the current set of contact points, not when a
touch started or ended. Track that state yourself to get began/moved/ended
semantics:

```js
const touch = new device.sensor.Touch({
    onSample() {
        const points = this.sample();
        if (!points) return;

        const last = this.points[0];

        if (points.length === 0) {
            if (last) {
                console.log("ended at " + last.x + ", " + last.y);
                this.points[0] = undefined;
            }
            return;
        }

        const { x, y } = points[0];

        if (last) {
            last.x = x;
            last.y = y;
            console.log("moved to " + x + ", " + y);
        } else {
            this.points[0] = { x, y };
            console.log("began at " + x + ", " + y);
        }
    }
});
touch.points = new Array(1);
```

> **Note**: For Piu apps, you generally don't need this sensor directly -
> Piu delivers `onTouchBegan`/`onTouchEnded` events to container Behaviors
> when `touchCount` is set on the Application. See the
> [Piu guide](/guides/alloy/piu-guide/) for details.

## Battery Status

Monitor battery level and charging state:

```js
import Battery from "embedded:sensor/Battery";

const battery = new Battery({
    onSample() {
        const sample = this.sample();
        console.log("battery " + sample.percent + "%, charging " +
              sample.charging + ", plugged " + sample.plugged);
    }
});

// Get current state immediately
const status = battery.sample();
console.log("battery " + status.percent + "%");
```

### Battery Sample Data

| Property | Type | Description |
|----------|------|-------------|
| `percent` | Number | Battery level (0-100) |
| `charging` | Boolean | Whether battery is charging |
| `plugged` | Boolean | Whether charger is connected |

## Connection Status

Monitor connection to the phone:

```js
function logConnected() {
    console.log("App connected: " + watch.connected.app);
    console.log("PebbleKitJS connected: " + watch.connected.pebblekit);
}

watch.addEventListener('connected', logConnected);
logConnected();
```

The `watch.connected` object has two properties:

| Property | Description |
|----------|-------------|
| `app` | Whether the Pebble app is connected |
| `pebblekit` | Whether PebbleKit JS is ready for messaging |

## Complete Example: Sensor Dashboard

Here's a complete example that displays sensor data:

```js
import Poco from "commodetto/Poco";
import Button from "pebble/button";
import Accelerometer from "embedded:sensor/Accelerometer";
import Battery from "embedded:sensor/Battery";

const render = new Poco(screen);
const font = new render.Font("Gothic-Regular", 18);
const black = render.makeColor(0, 0, 0);
const white = render.makeColor(255, 255, 255);

let accelData = { x: 0, y: 0, z: 0 };
let batteryPercent = 0;
let lastButton = "none";

// Setup accelerometer
const accel = new Accelerometer({
    onSample() {
        accelData = this.sample();
        draw();
    }
});
accel.configure({ hz: 10 });

// Setup battery monitor
const battery = new Battery({
    onSample() {
        batteryPercent = this.sample().percent;
        draw();
    }
});
batteryPercent = battery.sample().percent;

// Setup button handler
new Button({
    types: ["select", "up", "down"],
    onPush(down, type) {
        if (down) {
            lastButton = type;
            draw();
        }
    }
});

function draw() {
    render.begin();
    render.fillRectangle(white, 0, 0, render.width, render.height);

    render.drawText("Battery: " + batteryPercent + "%", font, black, 10, 10);
    render.drawText("Button: " + lastButton, font, black, 10, 35);
    render.drawText("Accel X: " + accelData.x.toFixed(2), font, black, 10, 60);
    render.drawText("Accel Y: " + accelData.y.toFixed(2), font, black, 10, 85);
    render.drawText("Accel Z: " + accelData.z.toFixed(2), font, black, 10, 110);

    render.end();
}

draw();
```

## Testing in the Emulator

When using the Pebble emulator, you can simulate sensor input:

### Battery
```text
$ pebble emu-battery --percent 20 --charging --qemu localhost:12344
```

### Accelerometer
```text
$ pebble emu-accel tilt-left --qemu localhost:12344
```

## Best Practices

1. **Clean up resources**: Sensors continue to consume power while active.
   Stop them when not needed.

2. **Appropriate sample rates**: Higher accelerometer sample rates use more
   power. Use the lowest rate that meets your needs.

3. **Handle disconnection gracefully**: Check connection status before
   attempting network operations.

## Examples

The [Pebble Examples](https://github.com/Moddable-OpenSource/pebble-examples)
repository includes sensor and input examples:

- [`hellobutton`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellobutton) - subscribing to button press and release events
- [`helloaccelerometer`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloaccelerometer) - reading accelerometer data and detecting taps
- [`hellobattery`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellobattery) - monitoring battery level and charging state
- [`hellolocation`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellolocation) - getting GPS location from the phone
- [`hellopoco-drag`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-drag) - draggable UI built on the `device.sensor.Touch` driver
- [`piu/apps/gravity`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/apps/gravity) - visualizes accelerometer readings with an animated display
- [`piu/apps/compass`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/apps/compass) - visualizes compass readings with a rotating compass rose
