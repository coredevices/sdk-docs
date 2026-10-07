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
title: Index 01
description: |
  What the Index 01 ring does, how the ring and the Pebble mobile app split
  the work, and the two ways to build on it.
permalink: /index-01/
generate_toc: true
search_index: true
search_group: Index 01
---

Index 01 is a ring with one button and a microphone. Press the button to
record a voice note. The ring sends the recording to the Pebble mobile app over
Bluetooth, and the app transcribes it, acts on it, and keeps it in the Index
feed. Developers can receive each recording at their own HTTP endpoint with a
[webhook](/index-01/webhooks/), or give the assistant new tools by connecting
an [MCP server](/index-01/mcp/).

## How the Ring and the App Split the Work

The ring firmware is a small fixed loop: it detects button presses, records
audio while the button is held, holds recordings until the phone collects
them, and transfers them over Bluetooth. It does not transcribe or interpret
anything. All of the logic lives in the Pebble mobile app, which is open
source at
[github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp).
The ring code is in the `experimental` module of that repository. This section
documents the app side only; there is no ring firmware SDK.

## Gestures

The button recognises five gestures. Each one is routed from the *Ring Button*
screen in the Index 01 settings of the Pebble mobile app. The three music
gestures can be configured on Android only; on iOS they are shown disabled.

| Gesture | Options |
|---------|---------|
| Click, Double click, Triple click | Play/Pause, Next track, or Nothing |
| Hold & Talk | Index agent, Web search, MCP sandbox, Webhook only, or Nothing |
| Double click & hold | Index agent, Web search, MCP sandbox, Webhook only, or Nothing |

The two hold gestures record a voice note. *Index agent* transcribes the note
and takes actions such as creating a note, a reminder, a timer, or a calendar
event. *Web search* answers a question and puts the answer in the feed. *MCP
sandbox* runs the recording through a sandbox group of MCP servers that you
choose. *Webhook only* sends the recording to your endpoint and does nothing
else. A recording gesture routed to *Index agent*, *Web search* or *MCP
sandbox* can also send a copy to its webhook with the *Also send to webhook*
switch; the switch is not shown for *Webhook only* or *Nothing*.

## Local and Cloud Processing

Where a recording is processed is a per-phone setting. The two steps are
configured separately in the Index 01 settings.

**Speech Recognition** turns audio into text. *Cloud only* sends the audio to
Core Devices' transcription service. *Cloud, with local fallback* uses the
cloud and falls back to an on-device model (a 400 MB download) when the phone
is offline. *Local only* always uses the on-device model. On iOS, *iOS Speech
Recognition* uses Apple's on-device recogniser.

**Agent Model** runs the assistant that reads the transcript and takes
actions. *Cloud LLM* runs in the cloud. *Local LLM* runs on the phone; it is
experimental, does not support every built-in action, and cannot call remote
MCP servers. *Cloud LLM (with Local fallback)* uses the Local LLM only when
the cloud cannot be reached.

Webhooks do not depend on either setting: the audio is sent as recorded, and
the transcript is whatever the selected speech recognition produced.

## Building on Index 01

There are two extension points.

* [Webhooks](/index-01/webhooks/) send each recording as a multipart HTTP
  POST to a URL you configure, with the audio, the transcript, or both, and an
  optional HMAC-SHA256 signature. Use this to feed recordings into your own
  service, an automation tool, or a note-taking app.
* [MCP servers](/index-01/mcp/) add tools to the assistant. The app connects
  to any MCP server over HTTP, lists its tools, and lets the Cloud LLM call
  them when it processes a recording.

## Where the Code Lives

Everything in this section is implemented in the Pebble mobile app at
[github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp):

| Area | Path |
|------|------|
| Webhook request format and signing | `experimental/src/commonMain/kotlin/coredevices/ring/external/indexwebhook/` |
| Gesture routing | `experimental/src/commonMain/kotlin/coredevices/ring/service/button/` |
| MCP settings screens | `experimental/src/commonMain/kotlin/coredevices/ring/ui/screens/settings/mcp/` |
| MCP client | `mcp/src/commonMain/kotlin/coredevices/mcp/client/` |
