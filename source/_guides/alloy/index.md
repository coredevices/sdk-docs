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

title: Alloy
description: |
  Build Pebble apps using modern JavaScript with the Alloy framework.
guide_group: alloy
menu: false
permalink: /guides/alloy/
generate_toc: false
hide_comments: true
---

Alloy is a JavaScript framework for building Pebble apps, based on the
[Moddable SDK](https://www.moddable.com/). Alloy provides developers a 
mix of standard Web APIs, standard Embedded JavaScript APIs from ECMA-419, 
and dedicated Pebble OS APIs. It allows you to write apps using
modern JavaScript (ES2025, ES6++) with powerful UI frameworks and access 
to Pebble hardware features.

> **Platform Support**: Alloy currently supports Emery (Pebble Time 2) and
> Gabbro (Pebble Round 2).

## Key Features

- **Modern JavaScript**: Write apps using ES modules, classes, async/await,
  and other modern JavaScript features
- **Two UI Frameworks**: Choose between Piu (declarative, component-based) or
  Poco (procedural, low-level graphics)
- **Hardware Access**: Full access to accelerometer, battery, buttons, compass,
  and other Pebble sensors
- **Network Communication**: Built-in support for HTTP requests, WebSockets,
  and watch-phone messaging
- **Persistent Storage**: Simple APIs for storing data locally using
  `localStorage`, key-value storage, or files

## Getting Started

To create a new Alloy project:

```text
$ pebble new-project --alloy my-app
```

This creates a new project with the standard Alloy structure:

```text
my-app/
  src/
    embeddedjs/
      main.js           # Watch code (runs on Pebble)
    pkjs/
      index.js          # Phone code (for networking, location)
    c/
      mdbl.c            # C code as entry point for embeddedjs (usually no need to modify)
  resources/            # App resources (images, fonts)
  package.json          # App manifest
```

Alloy apps have two JavaScript environments: **embeddedjs** runs on the watch,
while **pkjs** runs on the connected phone for network and location services.

## Hello World

The simplest Alloy app:

```javascript
console.log("Hello, Pebble!");
```

## Guides

{% include guides/contents-group.md group=site.data.guides.alloy %}

## Example Apps

The [Moddable Pebble Examples](https://github.com/Moddable-OpenSource/pebble-examples)
repository contains a collection of examples covering all aspects of Alloy
development. Here's a categorized overview:

### Fundamentals

| Example | Description |
|---------|-------------|
| [hellopebble](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopebble) | "Hello, world" - the simplest starting point |
| [hellotimer](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellotimer) | Using `setTimeout` |
| [hellomodule](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellomodule) | Loading multiple modules |
| [hellotypescript](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellotypescript) | TypeScript with the Pebble `Button` class |

### Storage

| Example | Description |
|---------|-------------|
| [hellokeyvalue](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellokeyvalue) | ECMA-419 Key-Value Storage for persistent data |
| [hellolocalstorage](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellolocalstorage) | Web standard `localStorage` for persisting strings |
| [hellofiles](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellofiles) | File system storage |

### Sensors & Input

| Example | Description |
|---------|-------------|
| [helloaccelerometer](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloaccelerometer) | Subscribing to accelerometer readings |
| [hellobattery](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellobattery) | Battery and charging status |
| [hellolocation](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellolocation) | GPS location via phone |
| [hellobutton](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellobutton) | Pebble button events |
| [hellopoco-drag](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-drag) | Touch events with the ECMA-419 touch driver |

### Piu UI Framework

| Example | Description |
|---------|-------------|
| [hellopiu-text](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-text) | Dynamic text layout with different fonts |
| [hellopiu-pebbletext](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-pebbletext) | Text using Pebble built-in fonts |
| [hellopiu-balls](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-balls) | Classic bouncing balls demo |
| [hellopiu-coloredsquares](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-coloredsquares) | Drawing colored squares |
| [hellopiu-gbitmap](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-gbitmap) | Pebble GBitmap PNG images as Piu textures |
| [hellopiu-jsicon](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-jsicon) | Moddable SDK bitmaps as Piu textures |
| [hellopiu-port](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-port) | Animated graph using Piu Port |
| [hellopiu-timeline](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopiu-timeline) | Easing equations with Timeline animation |

### Piu Watchfaces

| Example | Description |
|---------|-------------|
| [cupertino](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/watchfaces/cupertino) | Classic macOS watch cursor as a watchface |
| [london](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/watchfaces/london) | Big Ben (color watches only) |
| [helsinki](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/watchfaces/helsinki) | Minimal design with per-model assets |
| [redmond](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/watchfaces/redmond) | Classic Windows clock |
| [zurich](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/watchfaces/zurich) | Iconic Swiss railway clock |

### Poco Renderer

| Example | Description |
|---------|-------------|
| [hellopoco-text](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-text) | Text rendering with Moddable SDK fonts |
| [hellopoco-pebbletext](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pebbletext) | Text rendering with Pebble built-in fonts |
| [hellopoco-gbitmap](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-gbitmap) | Rendering GBitmap resources |
| [hellopoco-pebblegraphics](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pebblegraphics) | Lines, round rectangles, and circles |
| [hellopoco-qrcode](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-qrcode) | Dynamic QR code generation |
| [hellopoco-pdc](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc) | Rendering PDC (SVG) images |
| [hellopoco-pdc-rotate](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc-rotate) | Spinning a PDC image |
| [hellopoco-pdc-scale](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc-scale) | Animated PDC scaling with easing |
| [hellopoco-pdc-sequence](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellopoco-pdc-sequence) | PDC image sequence animation |
| [hellowatchface](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellowatchface) | Simple watchface app |

### Communication

| Example | Description |
|---------|-------------|
| [hellomessage](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellomessage) | Watch-phone messaging via app_message |
| [helloconnected](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloconnected) | Phone connection status notifications |
| [hellofetch](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellofetch) | HTTP requests using the `fetch()` API |
| [hellohttpclient](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellohttpclient) | HTTP requests using ECMA-419 HTTP Client |
| [hellowebsocket](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellowebsocket) | WebSocket using the Web standard API |
| [hellowebsocketclient](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellowebsocketclient) | WebSocket using ECMA-419 WebSocket Client |

### Sensor Visualizations (Piu)

| Example | Description |
|---------|-------------|
| [compass](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/apps/compass) | Compass visualization (Emery only) |
| [gravity](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/apps/gravity) | Accelerometer visualization (Emery only) |
| [tic-tac-toe](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/piu/apps/tic-tac-toe) | Touch game using Piu Behavior touch events |

### Device, Events & Feedback

| Example | Description |
|---------|-------------|
| [helloinfo](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloinfo) | Watch, screen, and device information |
| [helloappevents](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloappevents) | App focus and display resize events |
| [hellowakeup](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellowakeup) | Scheduling the app to launch later with wakeups |
| [hellodictation](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellodictation) | Capturing speech as text with dictation |
| [hellovibes](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellovibes) | Haptic feedback with the vibration motor |
| [hellolight](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellolight) | Controlling the backlight |

### Native Code

| Example | Description |
|---------|-------------|
| [helloffi](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/helloffi) | Calling native C functions from JavaScript (FFI) |

## Additional Resources

- [Moddable SDK Documentation](https://www.moddable.com/documentation/readme) -
  Comprehensive documentation for Piu, Poco, and other modules
