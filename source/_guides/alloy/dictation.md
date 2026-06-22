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

title: Dictation
description: |
  Capture speech as text in Alloy apps using the dictation API.
guide_group: alloy
order: 13
---

The `Dictation` class lets your Alloy app capture speech from the user and
receive it as text. It drives the system dictation UI and delivers the
transcription to your code through callbacks.

> **Platform Support**: Dictation is available on Emery (Pebble Time 2) and
> Gabbro (Pebble Time 2 round), and requires a connected phone with a working
> internet connection.

## Basic Usage

Import the class and create an instance with `onReadable` and `onError`
handlers, then call `start()` to begin listening:

```js
import Dictation from "pebble/dictation";

let dictation = new Dictation({
    onReadable() {
        console.log(`Transcription: ${this.read()}`);
    },
    onError(e) {
        console.log(`Dictation error: ${e}`);
    }
});

dictation.start();
```

## Methods

| Method | Description |
|--------|-------------|
| `start()` | Open the dictation UI and begin listening. |
| `stop()` | Stop an in-progress dictation session. |
| `read()` | Return the transcribed text. Call from `onReadable`. |
| `configure(options)` | Change dictation behavior (see [Configuration](#configuration)). |
| `close()` | Release the dictation instance when you're done with it. |

## Events

| Event | Description |
|-------|-------------|
| `onReadable()` | Called when a transcription is ready. Call `this.read()` to get the text. |
| `onError(status)` | Called when dictation fails (for example, no connection or no speech detected). `status` is a numeric error code. |

## Configuration

Pass a `byteLength` to the constructor to size the transcription buffer, and
use `configure()` to control the dictation UI:

```js
import Dictation from "pebble/dictation";

let dictation = new Dictation({
    byteLength: 512,   // maximum transcription size, in bytes
    onReadable() {
        console.log(`Transcription: ${this.read()}`);
    }
});

dictation.configure({
    confirm: false,       // skip the confirmation screen after dictation
    errorDialogs: true    // let the system show its own error dialogs
});

dictation.start();
```

| Option | Description |
|--------|-------------|
| `confirm` | Whether to show the confirmation screen after dictation (default `true`). |
| `errorDialogs` | Whether the system shows its own error UI on failure. |

## Continuous Dictation

To keep listening after each transcription, start a new session from within
`onReadable`. Use `setImmediate` so the current session finishes cleanly first:

```js
import Dictation from "pebble/dictation";

let dictation = new Dictation({
    onReadable() {
        console.log(`Transcription: ${this.read()}`);
        setImmediate(() => {
            console.log("Listening...");
            this.start();
        });
    },
    onError(e) {
        console.log(`Dictation error: ${e}`);
    }
});

console.log("Listening...");
dictation.start();
```

See the
[`hellodictation` example](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellodictation)
for a complete project.
