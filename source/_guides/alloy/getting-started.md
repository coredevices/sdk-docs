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

title: Getting Started with Alloy
description: |
  Learn how to create your first Alloy app for Pebble.
guide_group: alloy
order: 1
---

This guide walks you through creating your first Alloy app for Pebble.

> **Platform Support**: Alloy currently supports Emery (Pebble Time 2) and
> Gabbro (Pebble Round 2).

## Creating a New Project

Use the `pebble` command-line tool to create a new Alloy project:

```text
$ pebble new-project --alloy my-first-app
```

This creates a new directory with the following structure:

```text
my-first-app/
  src/
    embeddedjs/
      main.js           # Watch app code (runs on Pebble)
    pkjs/
      index.js          # Phone code (runs on connected phone)
  resources/            # App resources (images, fonts, etc.)
  package.json          # App manifest and configuration
```

## Project Structure

Alloy apps have **two JavaScript environments**:

| Location | File | Runs On | Purpose |
|----------|------|---------|---------|
| **embeddedjs** | `src/embeddedjs/main.js` | Watch | Your app UI and logic |
| **PKJS** | `src/pkjs/index.js` | Phone | Network proxy, location, config |

### Watch Code (embeddedjs)

The `src/embeddedjs/main.js` file is your watch app's entry point. This code
runs directly on the Pebble watch:

**⌚ Watch** (src/embeddedjs/main.js):

```javascript
console.log("Hello, Pebble!");
```

### Phone Code (PKJS)

The `src/pkjs/index.js` file runs on the connected phone. It's used for
network requests, GPS location, and configuration:

**📱 PKJS** (src/pkjs/index.js):

```javascript
Pebble.addEventListener("ready", function(e) {
    console.log("PebbleKit JS ready!");
});
```

### package.json

The `package.json` file contains your app's metadata and configuration:

```json
{
  "name": "My First App",
  "author": "Your Name",
  "version": "1.0.0",
  "keywords": ["pebble-app"],
  "private": true,
  "dependencies": {},
  "pebble": {
    "displayName": "My First App",
    "uuid": "12345678-1234-1234-1234-123456789abc",
    "projectType": "moddable",
    "sdkVersion": "3",
    "enableMultiJS": true,
    "targetPlatforms": ["emery"],
    "watchapp": {
      "watchface": false
    },
    "messageKeys": [],
    "resources": {
      "media": []
    }
  }
}
```

Key fields in the `pebble` section:

| Field | Description |
|-------|-------------|
| `displayName` | The name shown on the watch |
| `uuid` | Unique identifier for your app |
| `targetPlatforms` | Which Pebble platforms to build for |
| `watchapp.watchface` | Set to `true` for watchfaces, `false` for apps |
| `messageKeys` | Keys for watch-phone communication |

## Using ES Modules

Alloy uses standard ECMAScript modules. You can split your code across
multiple files and import them:

**math.js**

```javascript
export function add(a, b) {
    return a + b;
}

export function multiply(a, b) {
    return a * b;
}
```

**main.js**

```javascript
import { add, multiply } from "./math";

console.log("Sum: " + add(2, 3));       // 5
console.log("Product: " + multiply(4, 5));  // 20
```

### Declaring Modules in manifest.json

Each additional module must be listed in `src/embeddedjs/manifest.json` so
the Moddable build system knows to compile it. The default manifest only
includes `main.js`:

```json
"modules": {
    "*": "./main"
}
```

To add more modules, change the value to an array of paths. The `.js`
extension is optional:

```json
"modules": {
    "*": [
        "./main",
        "./math"
    ]
}
```

If you import a module that isn't listed here, you'll get a module-not-found
error at runtime.

## Important JavaScript Differences

Alloy runs on the XS JavaScript engine, which has some differences from
browser or Node.js JavaScript:

### Strict Mode
All code runs in strict mode by default.

### Hardened JavaScript
Built-in objects (primordials) are frozen and cannot be modified:

```javascript
// This will throw an error:
Array.prototype.myMethod = function() {};
```

### No eval()
Evaluation of JavaScript source code by eval, Function and friends is not supported to keep minimize the code footprint of the JavaScript engine.

## Debugging Output

Use `console.log()` for debug output:

```javascript
console.log("Debug message");
console.log("Value: " + someVariable);
```

Output appears in the Pebble emulator console or when viewing logs from a
physical watch.

> **Note**: `trace()` is also available as a lower-level alternative, but
> requires a manual newline (`\n`) at the end of each message. `console.log()`
> is recommended for most use cases.

## Building and Running

To build your app and run it in the emulator:

```text
$ pebble build
$ pebble install --emulator emery
```

To install on a physical watch:

```text
$ pebble install --phone YOUR_PHONE_IP
```

## Next Steps

Now that you have a basic app running, explore the following guides:

- [Piu UI Framework](/guides/alloy/piu-guide/): Build declarative user interfaces
- [Poco Graphics](/guides/alloy/poco-guide/): Low-level drawing and graphics
- [Sensors and Input](/guides/alloy/sensors-and-input/): Handle buttons and read sensors
- [Storage](/guides/alloy/storage/): Persist data between app launches
- [Networking](/guides/alloy/networking/): Make HTTP requests and use WebSockets
- [App Messages](/guides/alloy/app-messages/): Send and receive messages between watch and phone
