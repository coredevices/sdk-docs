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

title: Storage
description: |
  Persist data between app launches using localStorage, key-value storage, or files.
guide_group: alloy
order: 5
---

Alloy provides several ways to persist data on the watch: the Web standard
`localStorage` API, the ECMA-419 Key-Value Storage API, and a file system API.

> **Note**: All code in this guide runs on the watch in `src/embeddedjs/main.js`.

## localStorage (Recommended)

The `localStorage` API provides a simple, familiar way to store string data:

**⌚ Watch**:

```js
// Store a value
localStorage.setItem("username", "Alice");

// Retrieve a value
const username = localStorage.getItem("username");
console.log("username: " + username);  // "Alice"

// Remove a value
localStorage.removeItem("username");
```

### localStorage Methods

| Method | Description |
|--------|-------------|
| `setItem(key, value)` | Store a value |
| `getItem(key)` | Retrieve a value (returns `null` if not found) |
| `removeItem(key)` | Delete a value |
| `clear()` | Remove all stored values |

### Example: Persistent Counter

```js
// Get current count or start at 0
let counter = localStorage.getItem("counter");
if (counter === null) {
    console.log("initializing counter");
    counter = 1;
} else {
    counter = Number(counter) + 1;
}

if (counter < 5) {
    console.log("save counter value " + counter);
    localStorage.setItem("counter", counter);
} else {
    console.log("reset counter");
    localStorage.removeItem("counter");
}
```

### Storing Objects

Since `localStorage` only stores strings, serialize objects with JSON:

```javascript
// Store an object
const settings = {
    theme: "dark",
    notifications: true,
    fontSize: 14
};
localStorage.setItem("settings", JSON.stringify(settings));

// Retrieve the object
const stored = localStorage.getItem("settings");
if (stored) {
    const settings = JSON.parse(stored);
    console.log("theme: " + settings.theme);  // "dark"
}
```

## Key-Value Storage (ECMA-419)

For more control, and to be able to store binary data as well as strings, use
the ECMA-419 Key-Value Storage API:

```javascript
// Open a storage file
const store = device.keyValue.open({
    path: "mysettings",
    format: "string"
});

// Write a value
store.write("counter", "42");

// Read a value
const value = store.read("counter");
console.log("value: " + value);  // "42"

// Delete a value
store.delete("counter");

// Close when done
store.close();
```

### device.keyValue.open() Options

| Option | Description |
|--------|-------------|
| `path` | Name of the storage file (required) |
| `format` | Data format: `"string"` or `"buffer"` |

### Store Methods

| Method | Description |
|--------|-------------|
| `write(key, value)` | Store a value |
| `read(key)` | Retrieve a value (returns `undefined` if not found) |
| `delete(key)` | Remove a value |
| `close()` | Close the storage file |

### Example: Settings with Key-Value Storage

```javascript
const store = device.keyValue.open({ path: "appsettings", format: "string" });

// Save settings
function saveSettings(settings) {
    store.write("settings", JSON.stringify(settings));
}

// Load settings with defaults
function loadSettings() {
    const stored = store.read("settings");
    if (stored) {
        return JSON.parse(stored);
    }
    return {
        vibrate: true,
        brightness: 50
    };
}

const settings = loadSettings();
console.log("Vibrate: " + settings.vibrate);

// Modify and save
settings.brightness = 75;
saveSettings(settings);

store.close();
```

## Files (ECMA-419)

For storing larger data, use the file system API via `device.files`:

```javascript
const path = "example.json";

// Write a file
const jsonData = { name: "Alice", score: 1500 };
const data = ArrayBuffer.fromString(JSON.stringify(jsonData));
const save = device.files.openFile({ path, mode: "r+", size: data.byteLength });
save.write(data, 0);
save.close();

// Read a file
const load = device.files.openFile({ path });
const loaded = load.read(load.status().size, 0);
load.close();

const parsed = JSON.parse(String.fromArrayBuffer(loaded));
console.log(parsed.name);  // "Alice"

// Delete a file
device.files.delete(path);
```

### openFile() Options

| Option | Description |
|--------|-------------|
| `path` | File name (required) |
| `mode` | `"r"` for read-only (default), `"r+"` for read-write |
| `size` | File size in bytes (required when creating with `"r+"`) |

### File Methods

| Method | Description |
|--------|-------------|
| `write(buffer, offset)` | Write an ArrayBuffer at the given byte offset |
| `read(count, offset)` | Read `count` bytes from the given byte offset |
| `status()` | Returns an object with `size` property |
| `close()` | Close the file |
| `device.files.delete(path)` | Delete a file |

Files are disposable, so instead of calling `close()` manually you can open
them with a `using` declaration (SDK 4.33 and later) and they close
automatically at the end of the scope:

```js
using file = device.files.openFile({ path });
const loaded = file.read(file.status().size, 0);
```

## Choosing Between APIs

| Feature | localStorage | Key-Value Storage | Files |
|---------|--------------|-------------------|-------|
| API Style | Web standard | ECMA-419 | ECMA-419 |
| Simplicity | Simpler | Moderate | More verbose |
| Global access | Yes | Yes (`device.keyValue`) | Yes (`device.files`) |
| Multiple stores | No | Yes (different paths) | Yes (different paths) |
| Binary data | No (strings only) | Yes (buffer format) | Yes (ArrayBuffer) |
| Random access | No | No | Yes (read/write at offset) |

**Recommendation**: Use `localStorage` for most cases. Use Key-Value Storage
when you need multiple isolated stores or binary key-value pairs. Use Files
when you need random access or large binary data.

## Storage Limits

Pebble has limited storage space. Keep stored data minimal:

- Store only essential data
- Clean up old or unused data
- Avoid storing large objects
- Consider compressing data if storing significant amounts

## Data Persistence

Data stored with all three APIs persists across:

- App restarts
- Watch reboots
- App updates (unless the app is uninstalled)

Data is deleted when:

- The app is uninstalled
- The user performs a factory reset
- You explicitly delete it with `removeItem()` or `delete()`

## Error Handling

The storage APIs can fail if storage is full or corrupted:

```javascript
try {
    localStorage.setItem("key", "value");
} catch (e) {
    console.log("Failed to save data");
}
```

For Key-Value Storage:

```javascript
try {
    const store = device.keyValue.open({ path: "settings", format: "string" });
    store.write("key", "value");
    store.close();
} catch (e) {
    console.log("Storage error: " + e.message);
}
```

## Complete Example: High Score Tracker

```javascript
console.log("High Score Tracker");

// Load existing high scores
function loadHighScores() {
    const stored = localStorage.getItem("highscores");
    if (stored) {
        return JSON.parse(stored);
    }
    return [];
}

// Save high scores
function saveHighScores(scores) {
    localStorage.setItem("highscores", JSON.stringify(scores));
}

// Add a new score
function addScore(name, score) {
    const scores = loadHighScores();

    scores.push({ name, score, date: Date.now() });

    // Keep only top 10
    scores.sort((a, b) => b.score - a.score);
    scores.splice(10);

    saveHighScores(scores);
    console.log("Added score: " + name + " - " + score);
}

// Display high scores
function showHighScores() {
    const scores = loadHighScores();
    console.log("=== HIGH SCORES ===");
    scores.forEach((entry, i) => {
        console.log((i + 1) + ". " + entry.name + ": " + entry.score);
    });
}

// Example usage
addScore("Alice", 1500);
addScore("Bob", 2000);
addScore("Charlie", 1750);

showHighScores();
```

## Examples

The [Pebble Examples](https://github.com/Moddable-OpenSource/pebble-examples)
repository includes storage examples:

- [`hellolocalstorage`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellolocalstorage) - persisting strings with the `localStorage` API
- [`hellokeyvalue`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellokeyvalue) - key-value storage with string and binary data
- [`hellofiles`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellofiles) - reading and writing JSON data using `device.files`
