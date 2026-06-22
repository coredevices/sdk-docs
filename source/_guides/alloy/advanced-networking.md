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

title: Advanced Networking
description: |
  Low-level HTTP and WebSocket clients for advanced networking needs.
guide_group: alloy
order: 11
---

In addition to `fetch()` and `WebSocket`, Alloy provides low-level ECMA-419
networking APIs that offer more control over HTTP and WebSocket connections.
In fact, `fetch()` and `WebSocket()` are implemented using these ECMA-419 APIs.

> **Note**: Like `fetch()` and `WebSocket`, these APIs require the
> `@moddable/pebbleproxy` package. See below for setup.

## Proxy Setup

All networking APIs require proxy code running on the phone. Install the
`@moddable/pebbleproxy` package in your project directory:

```nc|text
$ pebble package install @moddable/pebbleproxy
```

Then add the proxy to your `src/pkjs/index.js`:

**📱 PKJS** (src/pkjs/index.js):

```js
const moddableProxy = require("@moddable/pebbleproxy");
Pebble.addEventListener('ready', moddableProxy.readyReceived);
Pebble.addEventListener('appmessage', moddableProxy.appMessageReceived);
```

If your app also needs to handle its own `ready` or `appmessage` events, you can call the proxy functions from your own event handlers:

```js
const moddableProxy = require("@moddable/pebbleproxy");

Pebble.addEventListener('ready', function(e) {
    moddableProxy.readyReceived(e);
    // Handle your own ready event here
})

Pebble.addEventListener('appmessage', function(e) {
    if (moddableProxy.appMessageReceived(e))
        return;

    // Handle your own app messages here
});
```

The `@moddable/pebbleproxy` package handles proxying for `fetch()`,
`WebSocket`, `HTTPClient`, and `WebSocketClient`.

## HTTPClient

The `HTTPClient` class provides streaming HTTP requests with fine-grained
control over headers and response handling.

### Using HTTPClient

**⌚ Watch** (src/embeddedjs/main.js):

```js
import HTTPClient from "embedded:network/http/client";

const http = new HTTPClient({
    host: "example.com"
});

http.request({
    path: "/",
    method: "GET",
    headers: new Map([
        ["User-Agent", "Pebble App"]
    ]),
    headersMask: ["content-type", "date"],
    onHeaders(status, headers, statusText) {
        console.log("Status: " + status + " " + statusText);
        headers.forEach((value, key) => {
            console.log(key + ": " + value);
        });
    },
    onReadable(count) {
        // Read response body in chunks
        const buffer = this.read(count);
        console.log(String.fromArrayBuffer(buffer));
    },
    onComplete() {
        console.log("Request complete");
    },
    onError(error) {
        console.log("Error: " + error);
    }
});
```

### HTTPClient Options

| Option | Description |
|--------|-------------|
| `host` | Target hostname |
| `port` | Port number (optional) |

### Request Options

| Option | Description |
|--------|-------------|
| `path` | URL path (e.g., `/api/data`) |
| `method` | HTTP method (default: `GET`) |
| `headers` | Map of request headers |
| `headersMask` | Array of header names to include in response |
| `body` | Request body (for POST/PUT) |

### Request Callbacks

| Callback | Description |
|----------|-------------|
| `onHeaders(status, headers, statusText)` | Response headers received |
| `onReadable(count)` | Response body data available (`count` is the number of bytes available to read) |
| `onComplete()` | Request completed successfully |
| `onError(error)` | Request failed |

## WebSocketClient

The `WebSocketClient` class provides a low-level WebSocket connection with
streaming support.

### Using WebSocketClient

**⌚ Watch** (src/embeddedjs/main.js):

```js
import WebSocketClient from "embedded:network/websocket/client";

const ws = new WebSocketClient({
    ...device.network.ws,   // use device.network.wss for secure (wss://) connections
    host: "websockets.chilkat.io",
    path: "/wsChilkatEcho.ashx",
    onReadable(count, options) {
        console.log("Received " + count + " bytes, binary: " + options.binary);
        const data = this.read();
        console.log(String.fromArrayBuffer(data));
    },
    onWritable(count) {
        console.log("Ready to write " + count + " bytes");
        this.write(ArrayBuffer.fromString("Hello!"), { binary: false });
    },
    onClose() {
        console.log("Connection closed");
    },
    onError() {
        console.log("Connection error");
    }
});
```

### WebSocketClient Callbacks

| Callback | Description |
|----------|-------------|
| `onReadable(count, options)` | Data received from server |
| `onWritable(count)` | Ready to send data |
| `onClose()` | Connection closed |
| `onError()` | Connection error occurred |

## HTTPClient vs fetch()

| Feature | HTTPClient | fetch() |
|---------|------------|---------|
| API style | ECMA-419 callbacks | Promise-based |
| Streaming | Yes | No |
| Header control | Fine-grained with mask | Basic |
| Best for | Large responses, streaming | Simple API calls |

## WebSocketClient vs WebSocket

| Feature | WebSocketClient | WebSocket |
|---------|-----------------|-----------|
| API style | ECMA-419 callbacks | Web standard events |
| Streaming | Yes | No |
| Best for | Low-level control | Simple messaging |

## Examples

The [Pebble Examples](https://github.com/Moddable-OpenSource/pebble-examples)
repository includes advanced networking examples:

- [`hellohttpclient`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellohttpclient) - HTTP requests using the ECMA-419 `HTTPClient`
- [`hellowebsocketclient`](https://github.com/Moddable-OpenSource/pebble-examples/tree/main/hellowebsocketclient) - WebSocket connections using the ECMA-419 `WebSocketClient`
