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
title: MCP Servers
description: |
  How to connect your own MCP server to Index 01 so the assistant can call
  its tools when it processes a recording.
permalink: /index-01/mcp/
generate_toc: true
search_index: true
search_group: Index 01
---

The Index 01 assistant calls tools through the
[Model Context Protocol](https://modelcontextprotocol.io). The built-in
actions (notes, reminders, timers, calendar, messaging) are MCP servers inside
the Pebble mobile app. You can add your own server over HTTP, and the assistant
lists its tools and calls them when a recording asks for something they do.

The MCP client is in `mcp/src/commonMain/kotlin/coredevices/mcp/client/` and
the settings screens are in
`experimental/src/commonMain/kotlin/coredevices/ring/ui/screens/settings/mcp/`
of [github.com/coredevices/mobileapp](https://github.com/coredevices/mobileapp).

## Requirements

* The server speaks MCP over HTTP with either the SSE transport or the
  Streamable HTTP transport. Pick the matching one when you add the server.
* The URL is reachable from the phone. Use HTTPS unless the server is on the
  same local network as the phone.
* Authentication, if any, is a single static `Authorization` header value.
  OAuth flows are not supported.
* `tools/list` returns every tool in one page. The app does not follow
  `nextCursor`.
* Prompts are optional. Only prompts without arguments are offered, and only
  the text of the first message of a prompt is used.
* Servers are called by a cloud model. See
  [Cloud LLM Only](#cloud-llm-only).

## Adding a Server

In the Pebble mobile app:

* Open the Index 01 settings and tap *MCP & Tool Settings*.
* Open the *MCP Servers* tab and tap *Add MCP Server*.
* Enter a *Name*. Letters, digits, `-` and `_` only, up to 32 characters. The
  name identifies the server in the app and in tool names.
* Enter the *URL*. The app connects as you type, shows the server's title
  under the field when the connection works, and shows the error when it does
  not. A server that cannot be reached can still be saved.
* Choose *SSE* or *Streamable* to match the server's transport. *SSE* is the
  default.
* Under *Groups*, pick the sandbox groups the server belongs to. See
  [Sandbox Groups](#sandbox-groups).
* To authenticate, expand *Authorization (optional)* and enter the full header
  value, for example `Bearer token123`.
* If the server offers prompts, expand *Prompts* and select the ones to
  include.
* Tap *Save*.

Edit a server by tapping it in the list. *Delete* removes it from every
group.

### The Authorization Header

The value you enter is sent as the `Authorization` header on every request the
app makes to the server, including the connection check in the dialog, as
entered. Include the scheme, so `Bearer <token>` rather than the bare token.
The app does not refresh or rotate it. Leave the field empty for a server
without authentication.

### Prompts and Instructions

The `instructions` string a server returns from `initialize` is added to the
assistant's context whenever the server is in the active group. Prompts you
select in the dialog are fetched with `prompts/get` and appended after the
instructions. Use them for standing guidance on when and how to call the
server's tools.

### Caching

The app caches `tools/list` and `prompts/list` results. If the server declares
`listChanged` for tools or prompts, the cache lasts one hour and is cleared
when the server sends the corresponding `notifications/*/list_changed`
notification. Otherwise it lasts five minutes.

## Sandbox Groups

A sandbox group is a set of MCP servers and the model that runs them. The
*Groups* tab in *MCP & Tool Settings* lists them. Every phone has a group
named *Default MCP Sandbox* that runs the Index agent with the built-in
actions; servers you add to it are available to a gesture routed to *Index
agent*. You can also create your own groups and route a recording gesture to
one by choosing *MCP sandbox* on the *Ring Button* screen.

Each group has a *Model Type*:

| Model type | Behaviour |
|------------|-----------|
| Index Agent | The default Index assistant. Understands notes and the built-in actions. Cannot be customised. |
| Default | Fast at intent recognition. Fine for most tool sets. |
| High Capability | Slower. Better with large numbers of tools and more complex tasks. |

Deleting a group does not delete its servers; they can be added to other
groups.

## Cloud LLM Only

Remote MCP servers are always called by a cloud model. The *Agent Model*
setting in the Index 01 settings applies to the Index agent, which is what
runs the *Default MCP Sandbox* group and any group whose model type is *Index
Agent*:

* With *Cloud LLM* or *Cloud LLM (with Local fallback)*, HTTP servers in the
  default group are available to the Index agent.
* With *Local LLM*, HTTP servers in the default group are shown as disabled
  with the reason "Remote MCP servers need the Cloud LLM". The on-device
  model also does not support every built-in action.
* The *Local LLM* options cannot be selected while the default group's model
  type is *Default* or *High Capability*. Changing the default group to one of
  those model types switches *Agent Model* back to *Cloud LLM*.

Groups with the *Default* or *High Capability* model type run in the cloud
whatever *Agent Model* is set to, and a gesture can be routed to them under
any setting. They need a signed-in Pebble account.
