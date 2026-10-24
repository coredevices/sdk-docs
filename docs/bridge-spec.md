# PebbleBridge — Generic Config Page Native Bridge

This document defines a generic JavaScript bridge that the Pebble mobile app (`coredevices/mobileapp`) can expose to watch-app configuration pages. The bridge lets config pages perform native HTTP/WebSocket requests and store sensitive tokens without being blocked by WebView CORS, mixed-content, or certificate restrictions.

The bridge is **opt-in**. Watch apps declare the capability in `appinfo.json`:

```json
{
  "capabilities": [
    "configurable",
    "config_network_bridge"
  ]
}
```

Only pages opened for apps that declare `config_network_bridge` receive the bridge. This keeps the change backward-compatible and avoids exposing an attack surface to unrelated watch apps.

## Scope

The bridge is scoped to the lifetime of the config WebView. It is not a background service. When the user closes the config page, the bridge is destroyed and any in-flight requests are cancelled.

All methods are exposed on a global object:

```js
window.pebbleBridge
```

## API Reference

### `version`

Type: `string`

Read-only version of the bridge API, e.g. `"1.0.0"`. Config pages can use this to detect whether the bridge is available and to branch on supported features.

```js
if (window.pebbleBridge && window.pebbleBridge.version) {
  // bridge is available
}
```

### `fetch(url, options)`

Performs an HTTP request through the native app's networking stack. Resolves with a Response-like object.

- `url` (`string`): Request URL.
- `options` (`object`, optional):
  - `method` (`string`): HTTP method. Default: `"GET"`.
  - `headers` (`object`): Header key/value map.
  - `body` (`string` | `ArrayBuffer`): Request body.
  - `timeout` (`number`): Timeout in milliseconds. Default: `30000`.

Returns a `Promise` that resolves to:

```ts
{
  ok: boolean;
  status: number;
  statusText: string;
  headers: Record<string, string>;
  text: () => Promise<string>;
  json: () => Promise<object>;
}
```

The native app is responsible for DNS resolution, TLS certificate validation, and obeying the Android/iOS network security configuration. The config page is not subject to browser CORS or mixed-content policies.

Example:

```js
const res = await window.pebbleBridge.fetch(
  'https://homeassistant.local:8123/api/config/entity_registry/list',
  {
    method: 'GET',
    headers: { 'Authorization': 'Bearer ' + token }
  }
);
const entities = (await res.json()).result;
```

### `WebSocket`

A WebSocket factory that creates a WebSocket-like object backed by the native app's networking stack.

```js
const ws = new window.pebbleBridge.WebSocket('wss://homeassistant.local:8123/api/websocket');

ws.onopen = () => ws.send(JSON.stringify({ type: 'auth', access_token: token }));
ws.onmessage = (event) => console.log(JSON.parse(event.data));
ws.onerror = (event) => console.error(event);
ws.onclose = (event) => console.log('closed', event.code, event.reason);
```

The returned object implements the standard `WebSocket` interface:

- `send(data)`
- `close(code?, reason?)`
- `readyState`
- `binaryType`
- Events: `open`, `message`, `error`, `close`

Native certificate handling applies, so self-signed or private-CA certificates trusted at the OS level are accepted on both platforms.

### `storage`

A simple key/value store backed by the native app's encrypted storage. Values are scoped to the watch app that opened the config page and are persisted across config sessions.

#### `storage.get(key)`

Returns a `Promise` that resolves to the stored string, or `null` if the key does not exist.

```js
const token = await window.pebbleBridge.storage.get('ha_token');
```

#### `storage.set(key, value)`

Stores a string value.

```js
await window.pebbleBridge.storage.set('ha_token', token);
```

#### `storage.remove(key)`

Removes a key.

```js
await window.pebbleBridge.storage.remove('ha_token');
```

Only string values are guaranteed. If a non-string value is passed to `set`, the bridge serializes it as JSON and deserializes it on `get`. Callers should treat the store as string-first.

### `config`

Type: `object`

Read-only copy of the Pebble settings that the watch app passed to the config page when it was opened. This replaces the data currently encoded in the URL hash. Keeping it out of the URL improves security (no token in browser history) and removes URL length limits.

```js
const currentSettings = window.pebbleBridge.config;
console.log(currentSettings.ha_url);
```

### `close(returnValue)`

Closes the config page and returns a value object to the watch app, equivalent to the existing `webviewclosed` flow.

```js
await window.pebbleBridge.close({
  ha_url: 'https://homeassistant.local:8123',
  token: '...',
  favorite_entities: [...]
});
```

If the page uses a traditional HTML form submit button instead, the existing behavior is unchanged. `close()` is provided for single-page config experiences.

## Security considerations

- The bridge is only injected for apps that declare `config_network_bridge`.
- The bridge does not expose arbitrary files, contacts, or other phone data.
- `fetch` and `WebSocket` do not bypass certificate validation; they use the OS-level trust store.
- `storage` is scoped to the watch app's UUID and is not shared between apps.
- Secrets are not placed in the URL hash or `localStorage` of the remote page.

## Backward compatibility

Watch apps that do not declare `config_network_bridge` continue to work exactly as before. Config pages should detect the bridge before using it:

```js
const bridge = window.pebbleBridge;
if (!bridge) {
  // fall back to the existing URL-hash / localStorage flow
}
```

This allows the same config page to support old Pebble apps, old versions of `coredevices/mobileapp`, and the new bridged flow.

## Implementation Status

- **Android**: Implemented in `coredevices/mobileapp` (PR #300)
- **iOS**: Not yet implemented (design sketch exists)

For implementation details, see the Android source in `coredevices/mobileapp/pebble/src/androidMain/kotlin/coredevices/pebble/config/bridge/`.
