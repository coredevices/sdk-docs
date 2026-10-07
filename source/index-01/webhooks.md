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

layout: index-01
title: Webhooks
description: |
  The HTTP request the Pebble mobile app sends for each Index 01 recording,
  how to verify its signature, and how to test a receiver.
permalink: /index-01/webhooks/
generate_toc: true
search_index: true
search_group: Index 01
---

A webhook sends each Index 01 recording to a URL you choose as a
`multipart/form-data` POST. The request carries the audio as an M4A file, the
transcript as text, or both, and can be signed with HMAC-SHA256. The Pebble
mobile app sends the request; the ring is not involved.

This page describes webhook protocol version `1`, which the app announces in
the `X-Index-Webhook-Version` header. The implementation is in
`experimental/src/commonMain/kotlin/coredevices/ring/external/indexwebhook/`
of [github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp).

## Setting Up a Webhook

Each recording gesture (*Hold & Talk* and *Double click & hold*) has its own
webhook with its own URL, headers, payload mode and signing secret.

In the Pebble mobile app:

* Open the Index 01 settings and tap *Webhook*. The same sheet opens from
  *Ring Button* > *Webhook settings*.
* Pick the gesture to configure. *Copy from* copies the other gesture's
  settings.
* Enter the *Webhook URL*. The app follows redirects and treats any 2xx
  response as success.
* Under *What to send*, choose *Recording*, *Transcription* or *Both*.
* Add any request *Headers* your endpoint needs, such as an `Authorization`
  header. They are sent as entered on every request.
* To sign requests, turn on *Sign requests* and paste a *Signing secret*. Use
  at least 32 random bytes encoded as hex or base64url. The secret is stored
  in the Android Keystore or the iOS Keychain, not in the app's settings file.
* Tap *Send test event* to POST a test payload to the URL, then tap *Save*.

A gesture sends only after its configuration is saved with a URL. The switch
on the webhook row turns sending off without discarding the URL or headers.
*Remove webhook* deletes the configuration.

## When a Request Is Sent

The webhook runs alongside the normal recording pipeline and never blocks or
fails it.

* *Recording*: sent as soon as the audio has been transferred from the ring,
  before transcription starts.
* *Transcription* and *Both*: sent as soon as the transcript is saved, while
  the assistant is still processing the note. The request is sent even if the
  assistant step later fails.

A gesture routed to *Webhook only* sends the request and does nothing else
with the recording. A gesture routed to *Nothing* never sends. Notes recorded
or typed in the app without a ring gesture use the *Hold & Talk* webhook.

Each recording is delivered at most once while the app is running. A failed
delivery is recorded under *Recent runs* with the HTTP status or the error and
is not retried by itself. A receiver can still see the same `X-Index-Delivery`
value twice, for example when a recording is reprocessed after the app
restarts, so use the delivery ID to detect duplicates.

## Request Format

```text
POST <your webhook URL>
Content-Type: multipart/form-data; boundary=<uuid>
<each header you configured>
X-Index-Webhook-Version: 1
X-Index-Trigger: single-click-hold | double-click-hold | test-event
X-Audio-Size: <byte count of the audio part>   (when audio is included)
X-Index-Test: true                               (test events only)
X-Index-Signature: <lowercase hex HMAC-SHA256>  (when signing is on)
X-Index-Timestamp: <Unix time in seconds>       (when signing is on)
X-Index-Delivery: <delivery ID>                 (when signing is on)
```

### Headers

| Header | Value |
|--------|-------|
| `X-Index-Webhook-Version` | Always `1`. A request without this header comes from an app version that predates it. |
| `X-Index-Trigger` | `single-click-hold` for *Hold & Talk*, `double-click-hold` for *Double click & hold*, `test-event` for the test button. |
| `X-Audio-Size` | Size in bytes of the `audio` part. Only present when audio is included. |
| `X-Index-Test` | `true` on test events. Absent otherwise. |
| `X-Index-Signature` | Lowercase hex HMAC-SHA256 of the signed bytes described below. |
| `X-Index-Timestamp` | Unix time in seconds when the request was sent. |
| `X-Index-Delivery` | The recording's delivery ID, stable across retries of the same recording. Test events get a fresh UUID. |

The signature, timestamp and delivery headers are sent only when *Sign
requests* is on. Headers you configure cannot override any of the headers in
this table; the comparison is case-insensitive.

### Multipart Fields

| Field | Present | Value |
|-------|---------|-------|
| `audio` | *Recording* and *Both* | `Content-Type: audio/mp4`, filename `<deliveryId>.m4a`. AAC-LC in an M4A container, mono, 16 kHz. This is the same resampled audio the app transcribes. |
| `transcription` | *Transcription* and *Both* | The transcript as plain text. |
| `test` | Test events | `true`. |
| `recordedAt` | Always | Unix time in milliseconds when the recording was made. |
| `client` | Always | `ring`. |

Fields appear in this order. Each part is separated by `--<boundary>` and
CRLF line endings, and the body ends with `--<boundary>--`.

### Example Request

A *Both* request for a *Hold & Talk* recording, with signing on:

```text
POST /index HTTP/1.1
Host: example.com
Content-Type: multipart/form-data; boundary=7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Authorization: Bearer <your token>
X-Index-Webhook-Version: 1
X-Index-Trigger: single-click-hold
X-Audio-Size: 48213
X-Index-Signature: <64 hex characters>
X-Index-Timestamp: 1791244800
X-Index-Delivery: 6f1c2a3e-8b4d-4c5e-9f60-1a2b3c4d5e6f

--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="audio"; filename="6f1c2a3e-8b4d-4c5e-9f60-1a2b3c4d5e6f.m4a"
Content-Type: audio/mp4

<48213 bytes of M4A audio>
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="transcription"

Remind me to call the dentist tomorrow at nine.
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="recordedAt"

1791244798766
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="client"

ring
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d--
```

## Verifying the Signature

When *Sign requests* is on, the app computes HMAC-SHA256 over a text prefix
followed by the raw request body. The key is the UTF-8 bytes of the secret
exactly as entered.

```text
signed bytes = UTF8("v1\n" + timestamp + "\n" + deliveryId + "\n" + trigger + "\n" + isTest + "\n")
               || raw multipart body
X-Index-Signature = lowercase hex of HMAC-SHA256(secret, signed bytes)
```

`timestamp`, `deliveryId` and `trigger` are the values of `X-Index-Timestamp`,
`X-Index-Delivery` and `X-Index-Trigger`. `isTest` is `1` when `X-Index-Test`
is `true` and `0` otherwise. The `v1` prefix is `v` followed by the value of
`X-Index-Webhook-Version`. Each line ends with a single `\n` (0x0A), including
the last one.

A receiver should:

* Accept only HTTPS.
* Read the raw body bytes before any multipart parser touches them.
* Reject requests whose `X-Index-Webhook-Version` is not `1` or whose
  timestamp does not parse.
* Rebuild the signed bytes and compare the signatures with a constant-time
  comparison.
* Reject timestamps outside a short window. The app sets the timestamp when
  it sends the request, so five minutes allows for a slow upload and clock
  drift.
* Remember accepted `X-Index-Delivery` values for at least that window and
  reject a repeat. A retried recording reuses its delivery ID, so a repeat
  within the window is either a replay or a duplicate you have already
  stored.

The signature authenticates the request and detects changes to it. It does not
encrypt the audio or the transcript.

### Worked Example

This is a complete test event, as sent by *Send test event*, signed with the
secret `0123456789abcdef0123456789abcdef`. Use it to check a verifier before
pointing the app at it.

Headers:

```text
X-Index-Webhook-Version: 1
X-Index-Trigger: test-event
X-Index-Test: true
X-Index-Timestamp: 1791244800
X-Index-Delivery: 6f1c2a3e-8b4d-4c5e-9f60-1a2b3c4d5e6f
X-Index-Signature: f3cda81969d98bfdaf2ed8e5e4019a8c3f2b99263e39a8c090c48d63c51738f7
Content-Type: multipart/form-data; boundary=7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
```

Body, 460 bytes. Every line break is CRLF (`\r\n`), including the last one:

```text
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="transcription"

Index webhook test event
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="test"

true
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="recordedAt"

1791244798766
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d
Content-Disposition: form-data; name="client"

ring
--7d3b8e5a-1f2c-4a6b-9c0d-2e4f6a8b0c1d--
```

The prefix is the 64 bytes
`v1\n1791244800\n6f1c2a3e-8b4d-4c5e-9f60-1a2b3c4d5e6f\ntest-event\n1\n`
(with `\n` as 0x0A). The signed bytes are the prefix followed by the 460-byte
body, and HMAC-SHA256 with the secret above gives
`f3cda81969d98bfdaf2ed8e5e4019a8c3f2b99263e39a8c090c48d63c51738f7`. The
SHA-256 of the body alone is
`dd947b94767662935ea27baa1e7e4297d7cc86513f66ff2d96b3c975b39b8d05`, which
you can use to check that your copy of the body has the right line endings.

## The Test Event

*Send test event* posts to the URL in the sheet with the headers, signing
setting and secret as currently entered, before they are saved. The payload
has no `audio` part, `transcription` is `Index webhook test event`, `test` is
`true`, `recordedAt` is the current time, `X-Index-Trigger` is `test-event`
and `X-Index-Test` is `true`. Each test event has a fresh `X-Index-Delivery`.
The result appears under *Recent runs* with the detail `test event`.

## Recent Runs

The sheet lists the last 20 deliveries for the selected gesture. Each entry
shows the time, the HTTP status, what was sent (`recording`, `transcription`,
`recording + transcription` or `test event`), the body size and the time the
request took. For a failed delivery the entry shows the status and the first
200 characters of the response body, or the error message when the request
did not complete. Timeouts are two minutes.

## Receiver Examples

Both examples verify the signature and the timestamp and reject repeated
delivery IDs, then hand the raw body to whatever multipart parser you use. Run
one with the secret from the worked example and send the request above to it.

### Node

```js
const http = require('http');
const crypto = require('crypto');

const secret = process.env.INDEX_WEBHOOK_SECRET;
const seen = new Map();   // deliveryId -> expiry (ms)

http.createServer((req, res) => {
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const h = req.headers;
    const now = Math.floor(Date.now() / 1000);
    const ts = Number(h['x-index-timestamp']);

    if (h['x-index-webhook-version'] !== '1' || !Number.isInteger(ts)) {
      res.writeHead(400); return res.end();
    }
    if (Math.abs(now - ts) > 300) { res.writeHead(401); return res.end(); }

    const prefix = `v1\n${ts}\n${h['x-index-delivery']}\n${h['x-index-trigger']}\n` +
                   `${h['x-index-test'] === 'true' ? 1 : 0}\n`;
    const expected = crypto.createHmac('sha256', secret)
      .update(Buffer.concat([Buffer.from(prefix, 'utf8'), body])).digest();
    const given = Buffer.from(h['x-index-signature'] || '', 'hex');
    if (given.length !== expected.length || !crypto.timingSafeEqual(given, expected)) {
      res.writeHead(401); return res.end();
    }

    const id = h['x-index-delivery'];
    for (const [k, exp] of seen) if (exp < Date.now()) seen.delete(k);
    if (seen.has(id)) { res.writeHead(409); return res.end(); }
    seen.set(id, Date.now() + 300_000);

    // body is the raw multipart payload; parse it with the library of your choice.
    res.writeHead(200); res.end();
  });
}).listen(8080);
```

### Python

```python
import hashlib
import hmac
import os
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

SECRET = os.environ["INDEX_WEBHOOK_SECRET"].encode()
seen = {}  # delivery id -> expiry


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        h = self.headers
        now = int(time.time())

        if h.get("X-Index-Webhook-Version") != "1":
            return self.reply(400)
        try:
            ts = int(h.get("X-Index-Timestamp", ""))
        except ValueError:
            return self.reply(400)
        if abs(now - ts) > 300:
            return self.reply(401)

        is_test = "1" if h.get("X-Index-Test") == "true" else "0"
        prefix = f"v1\n{ts}\n{h.get('X-Index-Delivery', '')}\n{h.get('X-Index-Trigger', '')}\n{is_test}\n"
        expected = hmac.new(SECRET, prefix.encode() + body, hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, h.get("X-Index-Signature", "")):
            return self.reply(401)

        delivery = h.get("X-Index-Delivery", "")
        for k in [k for k, exp in seen.items() if exp < now]:
            del seen[k]
        if delivery in seen:
            return self.reply(409)
        seen[delivery] = now + 300

        # body is the raw multipart payload; parse it with the library of your choice.
        self.reply(200)

    def reply(self, status):
        self.send_response(status)
        self.end_headers()


HTTPServer(("", 8080), Handler).serve_forever()
```

Both replay caches are in memory. A service with more than one instance should
keep accepted delivery IDs in a shared store with a time-to-live instead.
