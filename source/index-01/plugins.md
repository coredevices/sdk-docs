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
title: Plugins
description: |
  How Index 01 will call plugin actions, and why it cannot yet.
permalink: /index-01/plugins/
generate_toc: true
search_index: true
search_group: Index 01
---

A plugin is JavaScript in a `.pbw` that runs inside the Pebble mobile app and
offers data sources and actions to other apps. The plan is for the Index 01
assistant to call plugin actions as tools, in the same way it calls the tools
of an [MCP server](/index-01/mcp/), so that adding a to-do list or smart home
service to Index means writing a plugin rather than changing the app. Each
action's `description` and `parameters` schema in the plugin manifest are
written with this in mind.

This is not available yet. The assistant cannot see or call plugins. Plugins
themselves are a preview that is off by default; see
{% guide_link plugins %} for what they are, how to turn them
on, and how to write one.
